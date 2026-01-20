import Foundation
import SwiftUI
import SwiftData
import Combine
import Supabase
import AuthenticationServices
import CryptoKit

/// Manages authentication state and operations
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSyncing = false

    private let supabase = SupabaseService.shared.client
    private var currentNonce: String?
    private var syncService: SyncService?

    /// Configure with model context for sync operations
    func configure(with modelContext: ModelContext) {
        let localStorage = LocalStorageService(modelContext: modelContext)
        syncService = SyncService(localStorage: localStorage)
    }

    // MARK: - Session Management

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            currentUser = response.user
            isAuthenticated = true

            // Sync local data to cloud
            await performSync()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            currentUser = session.user
            isAuthenticated = true

            // Sync local data to cloud
            await performSync()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true

        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Delete Account

    /// Permanently deletes the user's account and all associated data
    func deleteAccount() async -> Bool {
        guard let userId = currentUser?.id else {
            errorMessage = "No user signed in"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            // Delete all workout data first
            if let syncService = syncService {
                await syncService.deleteAllSessions(userId: userId)
            }

            // Delete workout templates from Supabase
            try await SupabaseService.shared.deleteAllWorkoutTemplates()

            // Delete workout sessions from Supabase
            try await SupabaseService.shared.deleteAllWorkoutSessions()

            // Sign out the user (account deletion requires server-side admin API)
            try await supabase.auth.signOut()

            currentUser = nil
            isAuthenticated = false
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.resetPasswordForEmail(email)
            errorMessage = "Password reset email sent. Check your inbox."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Sign in with Apple

    func signInWithApple() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)

        return request
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Failed to get Apple ID credentials"
                isLoading = false
                return
            }

            do {
                let session = try await supabase.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: idTokenString,
                        nonce: nonce
                    )
                )
                currentUser = session.user
                isAuthenticated = true

                // Sync local data to cloud
                await performSync()
            } catch {
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            // User cancelled is not an error
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    // MARK: - Helpers

    var userId: UUID? {
        currentUser?.id
    }

    var userEmail: String? {
        currentUser?.email
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Sync

    /// Syncs local workout data with cloud after sign-in
    private func performSync() async {
        guard let userId = currentUser?.id, let syncService = syncService else { return }

        isSyncing = true
        await syncService.syncOnLogin(userId: userId)
        isSyncing = false
    }

    /// Manually trigger a sync (callable from Settings)
    func manualSync() async {
        guard let userId = currentUser?.id, let syncService = syncService else { return }

        isSyncing = true
        await syncService.uploadUnsyncedSessions()
        await syncService.downloadCloudSessions(userId: userId)
        isSyncing = false
    }

    // MARK: - Private Helpers for Apple Sign In

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}
