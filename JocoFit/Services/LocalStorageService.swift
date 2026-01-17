import Foundation
import SwiftData

/// Handles local SwiftData persistence for workout sessions
@MainActor
final class LocalStorageService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Save

    func saveSession(_ session: WorkoutSession) {
        modelContext.insert(session)
        try? modelContext.save()
    }

    // MARK: - Fetch

    func fetchAllSessions() -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchSession(by id: UUID) -> WorkoutSession? {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func fetchUnsyncedSessions() -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { !$0.isSynced },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchSessionsForUser(_ userId: UUID?) -> [WorkoutSession] {
        let descriptor: FetchDescriptor<WorkoutSession>
        if let userId = userId {
            descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate { $0.userId == userId || $0.userId == nil },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        } else {
            // Guest mode - only show sessions without userId
            descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate { $0.userId == nil },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        }
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Update

    func markAsSynced(_ sessionIds: [UUID]) {
        for id in sessionIds {
            if let session = fetchSession(by: id) {
                session.isSynced = true
            }
        }
        try? modelContext.save()
    }

    func assignUserToSessions(userId: UUID) {
        // Assign userId to all guest sessions (where userId is nil)
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.userId == nil }
        )
        if let guestSessions = try? modelContext.fetch(descriptor) {
            for session in guestSessions {
                session.userId = userId
                session.isSynced = false // Mark for sync
            }
            try? modelContext.save()
        }
    }

    // MARK: - Delete

    func deleteSession(_ id: UUID) {
        if let session = fetchSession(by: id) {
            modelContext.delete(session)
            try? modelContext.save()
        }
    }

    func deleteAllSessions() {
        let sessions = fetchAllSessions()
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }

    // MARK: - Stats

    func calculateStats(for sessions: [WorkoutSession]) -> WorkoutStats {
        let total = sessions.count
        let completed = sessions.filter { $0.completed }.count
        let totalReps = sessions.reduce(0) { $0 + $1.totalCompletedReps }
        let totalTime = sessions.reduce(0) { $0 + $1.totalWorkoutTimeSeconds }

        let completedSessions = sessions.filter { $0.completed }
        let bestTime = completedSessions.min(by: { $0.totalWorkoutTimeSeconds < $1.totalWorkoutTimeSeconds })
        let bestReps = sessions.max(by: { $0.totalCompletedReps < $1.totalCompletedReps })

        return WorkoutStats(
            totalSessions: total,
            completedSessions: completed,
            completionRate: total > 0 ? Double(completed) / Double(total) * 100 : 0,
            totalReps: totalReps,
            totalTimeSeconds: totalTime,
            bestTimeSeconds: bestTime?.totalWorkoutTimeSeconds,
            bestReps: bestReps?.totalCompletedReps
        )
    }
}
