import Foundation
import SwiftUI

/// Manages workout history and statistics
@Observable
final class HistoryViewModel {
    private(set) var sessions: [WorkoutSession] = []
    private(set) var stats: WorkoutStats?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var selectedModeFilter: String? = nil

    private let supabase = SupabaseService.shared

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

    // MARK: - Data Loading

    func loadSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            sessions = try await supabase.fetchWorkoutSessions()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadStats() async {
        do {
            stats = try await supabase.fetchWorkoutStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        await loadSessions()
        await loadStats()
    }

    // MARK: - Session Management

    func deleteSession(_ session: WorkoutSession) async {
        do {
            try await supabase.deleteWorkoutSession(session.id)
            sessions.removeAll { $0.id == session.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Personal Best

    func getBestSession(forMode mode: String) async -> WorkoutSession? {
        do {
            return try await supabase.fetchBestSession(forMode: mode)
        } catch {
            return nil
        }
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
