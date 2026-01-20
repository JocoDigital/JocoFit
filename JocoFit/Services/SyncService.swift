import Foundation
import SwiftData

/// Handles synchronization between local SwiftData and Supabase cloud storage
@MainActor
final class SyncService {
    private let localStorage: LocalStorageService
    private let supabase = SupabaseService.shared

    init(localStorage: LocalStorageService) {
        self.localStorage = localStorage
    }

    /// Syncs all local data when user signs in
    /// 1. Assigns userId to guest sessions
    /// 2. Uploads unsynced sessions to cloud
    /// 3. Downloads cloud sessions not in local storage
    func syncOnLogin(userId: UUID) async {
        // Step 1: Assign userId to any guest sessions
        localStorage.assignUserToSessions(userId: userId)

        // Step 2: Upload unsynced sessions to cloud
        await uploadUnsyncedSessions()

        // Step 3: Download cloud sessions we don't have locally
        await downloadCloudSessions(userId: userId)
    }

    /// Uploads all unsynced sessions to Supabase
    func uploadUnsyncedSessions() async {
        let unsyncedSessions = localStorage.fetchUnsyncedSessions()

        for session in unsyncedSessions {
            do {
                try await supabase.saveWorkoutSession(session)
                localStorage.markAsSynced([session.id])
            } catch {
                // Log error but continue with other sessions
                print("Failed to sync session \(session.id): \(error.localizedDescription)")
            }
        }
    }

    /// Downloads sessions from cloud that aren't in local storage
    func downloadCloudSessions(userId: UUID) async {
        do {
            let cloudSessions = try await supabase.fetchWorkoutSessions()

            for cloudSession in cloudSessions {
                // saveSessionIfNotExists handles deduplication
                localStorage.saveSessionIfNotExists(cloudSession)
            }
        } catch {
            print("Failed to download cloud sessions: \(error.localizedDescription)")
        }
    }

    /// Saves a session locally and optionally syncs to cloud if authenticated
    func saveSession(_ session: WorkoutSession, syncToCloud: Bool) async {
        // Always save locally first
        localStorage.saveSession(session)

        // Sync to cloud if requested and session has a userId
        if syncToCloud && session.userId != nil {
            do {
                try await supabase.saveWorkoutSession(session)
                localStorage.markAsSynced([session.id])
            } catch {
                // Local save succeeded, cloud sync will retry later
                print("Cloud sync failed, will retry: \(error.localizedDescription)")
            }
        }
    }

    /// Deletes a session from both local and cloud storage
    func deleteSession(_ sessionId: UUID, userId: UUID?) async {
        // Delete locally
        localStorage.deleteSession(sessionId)

        // Delete from cloud if authenticated
        if userId != nil {
            do {
                try await supabase.deleteWorkoutSession(sessionId)
            } catch {
                // Session deleted locally, cloud delete failed - acceptable
                print("Cloud delete failed: \(error.localizedDescription)")
            }
        }
    }

    /// Deletes all sessions from local and cloud storage
    func deleteAllSessions(userId: UUID?) async {
        // Delete locally
        localStorage.deleteAllSessions()

        // Delete from cloud if authenticated
        if userId != nil {
            do {
                try await supabase.deleteAllWorkoutSessions()
            } catch {
                print("Cloud delete all failed: \(error.localizedDescription)")
            }
        }
    }
}
