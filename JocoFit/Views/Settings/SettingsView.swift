import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignOutConfirmation = false
    @State private var showSignIn = false
    @State private var showDeleteAccountConfirmation = false
    @State private var isDeletingAccount = false

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section("Account") {
                    if authViewModel.isAuthenticated {
                        if let email = authViewModel.userEmail {
                            HStack {
                                Label("Email", systemImage: "envelope")
                                Spacer()
                                Text(email)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            Task {
                                await authViewModel.manualSync()
                            }
                        } label: {
                            if authViewModel.isSyncing {
                                HStack {
                                    Label("Syncing...", systemImage: "arrow.triangle.2.circlepath")
                                    Spacer()
                                    ProgressView()
                                }
                            } else {
                                Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                        .disabled(authViewModel.isSyncing)

                        Button(role: .destructive) {
                            showSignOutConfirmation = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        // Guest mode - show sign in option
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Guest Mode", systemImage: "person.crop.circle.badge.questionmark")
                                .font(.headline)
                            Text("Sign in to sync your workouts across devices and back up your data.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)

                        Button {
                            showSignIn = true
                        } label: {
                            Label("Sign In", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                }

                // App Info Section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://jocofit.com")!) {
                        Label("Website", systemImage: "globe")
                    }

                    Link(destination: URL(string: "https://jocofit.com/support.php")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }

                // Legal Section
                Section("Legal") {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                // Data Management
                Section("Data") {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Manage Data", systemImage: "externaldrive")
                    }
                }

                // Danger Zone - Account Deletion
                if authViewModel.isAuthenticated {
                    Section {
                        Button(role: .destructive) {
                            showDeleteAccountConfirmation = true
                        } label: {
                            if isDeletingAccount {
                                HStack {
                                    ProgressView()
                                    Text("Deleting Account...")
                                }
                            } else {
                                Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                            }
                        }
                        .disabled(isDeletingAccount)
                    } header: {
                        Text("Danger Zone")
                    } footer: {
                        Text("Permanently delete your account, all workout history, and saved templates. This action cannot be undone.")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Sign Out?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to access your workouts.")
            }
            .confirmationDialog(
                "Delete Account?",
                isPresented: $showDeleteAccountConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        isDeletingAccount = true
                        _ = await authViewModel.deleteAccount()
                        isDeletingAccount = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account, all workout history, and saved templates. This action cannot be undone.")
            }
            .sheet(isPresented: $showSignIn) {
                NavigationStack {
                    LoginView()
                        .navigationTitle("Sign In")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showSignIn = false
                                }
                            }
                        }
                }
            }
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    showSignIn = false
                }
            }
        }
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Link(destination: URL(string: "https://jocofit.com/privacy.php")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("View on jocofit.com")
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 8)

                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Last updated: January 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Group {
                    Text("Information We Collect")
                        .font(.headline)

                    Text("JocoFit collects the following information to provide our services:")
                    Text("• Email address for account authentication")
                    Text("• Workout data including exercises, reps, and timing")
                    Text("• App usage analytics (anonymous)")

                    Text("How We Use Your Information")
                        .font(.headline)
                        .padding(.top)

                    Text("Your information is used to:")
                    Text("• Provide and improve our workout tracking service")
                    Text("• Sync your workout history across devices")
                    Text("• Send important account notifications")

                    Text("Data Storage")
                        .font(.headline)
                        .padding(.top)

                    Text("Your data is securely stored using Supabase infrastructure with encryption at rest and in transit.")
                }
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Link(destination: URL(string: "https://jocofit.com/privacy.php")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("View on jocofit.com")
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 8)

                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Last updated: January 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Group {
                    Text("Acceptance of Terms")
                        .font(.headline)

                    Text("By using JocoFit, you agree to these terms of service.")

                    Text("Use of Service")
                        .font(.headline)
                        .padding(.top)

                    Text("JocoFit is a personal fitness tracking application. You are responsible for your own physical health and safety when performing any exercises tracked by this app.")

                    Text("Disclaimer")
                        .font(.headline)
                        .padding(.top)

                    Text("JocoFit is provided \"as is\" without warranty. Consult a healthcare provider before starting any exercise program.")
                }
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        List {
            Section {
                if authViewModel.isAuthenticated {
                    Text("Your workout data is synced to the cloud and stored securely. You can delete all your data at any time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Your workout data is stored locally on this device. Sign in to back up your data to the cloud.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    if isDeleting {
                        HStack {
                            ProgressView()
                            Text("Deleting...")
                        }
                    } else {
                        Label("Delete All Workout Data", systemImage: "trash")
                    }
                }
                .disabled(isDeleting)
            } footer: {
                Text("This will permanently delete all your workout history. This action cannot be undone.")
            }
        }
        .navigationTitle("Manage Data")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .confirmationDialog(
            "Delete All Data?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                Task {
                    await deleteAllData()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your workout history and cannot be undone.")
        }
        .alert("Data Deleted", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All your workout history has been deleted.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func deleteAllData() async {
        isDeleting = true

        // Delete local data
        let localStorage = LocalStorageService(modelContext: modelContext)
        let syncService = SyncService(localStorage: localStorage)
        await syncService.deleteAllSessions(userId: authViewModel.userId)

        showSuccessAlert = true
        isDeleting = false
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
