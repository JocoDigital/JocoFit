import Foundation
import Supabase

/// Centralized service for all Supabase operations
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        let supabaseURL = URL(string: "https://jcobqznsqmmjpwirmhgf.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impjb2Jxem5zcW1tanB3aXJtaGdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2NzQxNTEsImV4cCI6MjA4NDI1MDE1MX0.iNsrHKQh3dVrTbz3WkbHfol__vPv5ACvtIP46yzN6bk"

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }

    // MARK: - Auth Helpers

    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }

    // MARK: - Workout Sessions

    func saveWorkoutSession(_ session: WorkoutSession) async throws {
        guard let userId = session.userId else {
            throw SupabaseError.notAuthenticated
        }
        let dto = WorkoutSessionDTO(from: session, userId: userId)
        try await client.database
            .from("workout_sessions")
            .insert(dto)
            .execute()
    }

    func fetchWorkoutSessions(limit: Int = 50) async throws -> [WorkoutSession] {
        guard let userId = await currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let response: [WorkoutSessionDTO] = try await client.database
            .from("workout_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response.map { $0.toSession() }
    }

    func fetchWorkoutSessions(forMode mode: String, limit: Int = 50) async throws -> [WorkoutSession] {
        guard let userId = await currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let response: [WorkoutSessionDTO] = try await client.database
            .from("workout_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("workout_mode", value: mode)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response.map { $0.toSession() }
    }

    func fetchBestSession(forMode mode: String) async throws -> WorkoutSession? {
        guard let userId = await currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let response: [WorkoutSessionDTO] = try await client.database
            .from("workout_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("workout_mode", value: mode)
            .eq("completed", value: true)
            .order("total_workout_time_seconds", ascending: true)
            .limit(1)
            .execute()
            .value

        return response.first?.toSession()
    }

    func deleteWorkoutSession(_ sessionId: UUID) async throws {
        guard let userId = await currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        try await client.database
            .from("workout_sessions")
            .delete()
            .eq("id", value: sessionId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func deleteAllWorkoutSessions() async throws {
        guard let userId = await currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        try await client.database
            .from("workout_sessions")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Workout Templates

    func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws {
        let dto = WorkoutTemplateDTO(from: template)
        try await client.database
            .from("workout_templates")
            .insert(dto)
            .execute()
    }

    func fetchWorkoutTemplates() async throws -> [WorkoutTemplate] {
        guard let userId = await currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let response: [WorkoutTemplateDTO] = try await client.database
            .from("workout_templates")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response.map { $0.toTemplate() }
    }

    func deleteWorkoutTemplate(_ templateId: UUID) async throws {
        guard let userId = await currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        try await client.database
            .from("workout_templates")
            .delete()
            .eq("id", value: templateId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func deleteAllWorkoutTemplates() async throws {
        guard let userId = await currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        try await client.database
            .from("workout_templates")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func toggleTemplateFavorite(_ templateId: UUID, isFavorite: Bool) async throws {
        guard let userId = await currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        try await client.database
            .from("workout_templates")
            .update(["is_favorite": isFavorite])
            .eq("id", value: templateId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Statistics

    func fetchWorkoutStats() async throws -> WorkoutStats {
        guard let userId = await currentUserId else {
            throw SupabaseError.notAuthenticated
        }

        let sessions: [WorkoutSessionDTO] = try await client.database
            .from("workout_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let total = sessions.count
        let completed = sessions.filter { $0.completed }.count
        let totalReps = sessions.reduce(0) { $0 + $1.total_completed_reps }
        let totalTime = sessions.reduce(0) { $0 + $1.total_workout_time_seconds }

        let completedSessions = sessions.filter { $0.completed }
        let bestTime = completedSessions.min(by: { $0.total_workout_time_seconds < $1.total_workout_time_seconds })
        let bestReps = sessions.max(by: { $0.total_completed_reps < $1.total_completed_reps })

        return WorkoutStats(
            totalSessions: total,
            completedSessions: completed,
            completionRate: total > 0 ? Double(completed) / Double(total) * 100 : 0,
            totalReps: totalReps,
            totalTimeSeconds: totalTime,
            bestTimeSeconds: bestTime?.total_workout_time_seconds,
            bestReps: bestReps?.total_completed_reps
        )
    }
}

// MARK: - Error Types

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Statistics Model

struct WorkoutStats {
    let totalSessions: Int
    let completedSessions: Int
    let completionRate: Double
    let totalReps: Int
    let totalTimeSeconds: Int
    let bestTimeSeconds: Int?
    let bestReps: Int?

    var formattedCompletionRate: String {
        String(format: "%.1f%%", completionRate)
    }

    var formattedTotalTime: String {
        let hours = totalTimeSeconds / 3600
        let minutes = (totalTimeSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedBestTime: String? {
        guard let seconds = bestTimeSeconds else { return nil }
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
