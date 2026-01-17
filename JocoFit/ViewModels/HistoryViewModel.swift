import Foundation
import SwiftUI
import SwiftData

/// Manages workout history and statistics
@Observable
@MainActor
final class HistoryViewModel {
    private(set) var sessions: [WorkoutSession] = []
    private(set) var stats: WorkoutStats?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var selectedModeFilter: String? = nil

    private let supabase = SupabaseService.shared
    private var localStorage: LocalStorageService?

    // MARK: - Initialization

    func configure(with modelContext: ModelContext) {
        localStorage = LocalStorageService(modelContext: modelContext)
    }

    // MARK: - Computed Properties

    var filteredSessions: [WorkoutSession] {
        guard let filter = selectedModeFilter else {
            return sessions
        }
        return sessions.filter { $0.workoutMode == filter }
    }

    var uniqueModes: [String] {
        Array(Set(sessions.map { $0.workoutMode })).sorted()
    }

    var completedCount: Int {
        sessions.filter { $0.completed }.count
    }

    var partialCount: Int {
        sessions.filter { !$0.completed }.count
    }

    var completionRate: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(completedCount) / Double(sessions.count) * 100
    }

    var hasUnsyncedSessions: Bool {
        sessions.contains { !$0.isSynced }
    }

    // MARK: - Data Loading

    func loadSessions(userId: UUID?, isAuthenticated: Bool) async {
        isLoading = true
        errorMessage = nil

        // Always load from local storage first
        if let localStorage = localStorage {
            sessions = localStorage.fetchSessionsForUser(userId)
            stats = localStorage.calculateStats(for: sessions)
        }

        // If authenticated, also sync with cloud
        if isAuthenticated {
            do {
                let cloudSessions = try await supabase.fetchWorkoutSessions()

                // Merge cloud sessions into local
                if let localStorage = localStorage {
                    let localIds = Set(sessions.map { $0.id })
                    for cloudSession in cloudSessions {
                        if !localIds.contains(cloudSession.id) {
                            localStorage.saveSession(cloudSession)
                        }
                    }
                    // Reload after merge
                    sessions = localStorage.fetchSessionsForUser(userId)
                    stats = localStorage.calculateStats(for: sessions)
                }
            } catch {
                // Cloud fetch failed, local data still available
                errorMessage = "Using local data. Cloud sync unavailable."
            }
        }

        isLoading = false
    }

    func refresh(userId: UUID?, isAuthenticated: Bool) async {
        await loadSessions(userId: userId, isAuthenticated: isAuthenticated)
    }

    // MARK: - Session Management

    func deleteSession(_ session: WorkoutSession, userId: UUID?) async {
        // Delete locally
        localStorage?.deleteSession(session.id)
        sessions.removeAll { $0.id == session.id }

        // Also delete from cloud if authenticated
        if userId != nil {
            do {
                try await supabase.deleteWorkoutSession(session.id)
            } catch {
                // Local delete succeeded, cloud delete failed - acceptable
            }
        }

        // Recalculate stats
        if let localStorage = localStorage {
            stats = localStorage.calculateStats(for: sessions)
        }
    }

    // MARK: - Personal Best

    func getBestSession(forMode mode: String) -> WorkoutSession? {
        sessions
            .filter { $0.workoutMode == mode && $0.completed }
            .min { $0.totalWorkoutTimeSeconds < $1.totalWorkoutTimeSeconds }
    }

    func getRecentSessions(forMode mode: String, limit: Int = 5) -> [WorkoutSession] {
        sessions
            .filter { $0.workoutMode == mode }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Filtering

    func setFilter(_ mode: String?) {
        selectedModeFilter = mode
    }

    func clearFilter() {
        selectedModeFilter = nil
    }
}
