import Foundation
import SwiftData

/// Represents a completed or partially completed workout session
@Model
final class WorkoutSession {
    var id: UUID
    var userId: UUID? // nil for guest workouts
    var workoutMode: String
    var completed: Bool
    var completedRounds: Int
    var totalCompletedReps: Int
    var totalWorkoutTimeSeconds: Int
    var progressPercentage: Double
    var exerciseRepsData: Data? // JSON encoded [String: Int]
    var exerciseTimingData: Data? // JSON encoded [String: Int]
    var workoutStartedAt: Date
    var workoutEndedAt: Date?
    var createdAt: Date
    var isSynced: Bool // Tracks if session has been synced to cloud

    /// Returns true if this session needs to be synced to the cloud
    var needsSync: Bool {
        !isSynced && userId != nil
    }

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        workoutMode: String,
        completed: Bool = false,
        completedRounds: Int = 0,
        totalCompletedReps: Int = 0,
        totalWorkoutTimeSeconds: Int = 0,
        progressPercentage: Double = 0.0,
        exerciseReps: [String: Int] = [:],
        exerciseTiming: [String: Int] = [:],
        workoutStartedAt: Date = Date(),
        workoutEndedAt: Date? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.workoutMode = workoutMode
        self.completed = completed
        self.completedRounds = completedRounds
        self.totalCompletedReps = totalCompletedReps
        self.totalWorkoutTimeSeconds = totalWorkoutTimeSeconds
        self.progressPercentage = progressPercentage
        self.exerciseRepsData = try? JSONEncoder().encode(exerciseReps)
        self.exerciseTimingData = try? JSONEncoder().encode(exerciseTiming)
        self.workoutStartedAt = workoutStartedAt
        self.workoutEndedAt = workoutEndedAt
        self.createdAt = Date()
        self.isSynced = isSynced
    }

    // MARK: - Computed Properties

    var exerciseReps: [String: Int] {
        get {
            guard let data = exerciseRepsData else { return [:] }
            return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
        }
        set {
            exerciseRepsData = try? JSONEncoder().encode(newValue)
        }
    }

    var exerciseTiming: [String: Int] {
        get {
            guard let data = exerciseTimingData else { return [:] }
            return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
        }
        set {
            exerciseTimingData = try? JSONEncoder().encode(newValue)
        }
    }

    var formattedTime: String {
        let minutes = totalWorkoutTimeSeconds / 60
        let seconds = totalWorkoutTimeSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var workoutTitle: String {
        // Check if it's a custom workout
        if workoutMode.hasPrefix("custom_") {
            return formatCustomWorkoutTitle(workoutMode)
        }

        // Otherwise it's a preset
        if let preset = PresetWorkout(rawValue: workoutMode) {
            return preset.displayName
        }

        return workoutMode.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var isCustomWorkout: Bool {
        workoutMode.hasPrefix("custom_")
    }

    var statusText: String {
        completed ? "Completed" : "Partial"
    }

    // MARK: - Private Helpers

    private func formatCustomWorkoutTitle(_ mode: String) -> String {
        // Format: custom_pull_ups_push_ups_sit_ups_full
        var components = mode.replacingOccurrences(of: "custom_", with: "")
            .components(separatedBy: "_")

        // Last component is the progression mode
        guard let progressionString = components.popLast(),
              let progression = ProgressionMode(rawValue: progressionString) else {
            return mode
        }

        // Reconstruct exercise names
        let exerciseNames = components.joined(separator: " ").capitalized
        return "\(exerciseNames) - \(progression.displayName)"
    }
}

// MARK: - Supabase DTO

/// Data transfer object for Supabase operations
struct WorkoutSessionDTO: Codable {
    let id: UUID
    let user_id: UUID
    let workout_mode: String
    let completed: Bool
    let completed_rounds: Int
    let total_completed_reps: Int
    let total_workout_time_seconds: Int
    let progress_percentage: Double
    let exercise_reps: [String: Int]
    let exercise_timing: [String: Int]
    let workout_started_at: Date
    let workout_ended_at: Date?
    let created_at: Date?

    init(from session: WorkoutSession, userId: UUID) {
        self.id = session.id
        self.user_id = userId
        self.workout_mode = session.workoutMode
        self.completed = session.completed
        self.completed_rounds = session.completedRounds
        self.total_completed_reps = session.totalCompletedReps
        self.total_workout_time_seconds = session.totalWorkoutTimeSeconds
        self.progress_percentage = session.progressPercentage
        self.exercise_reps = session.exerciseReps
        self.exercise_timing = session.exerciseTiming
        self.workout_started_at = session.workoutStartedAt
        self.workout_ended_at = session.workoutEndedAt
        self.created_at = session.createdAt
    }

    func toSession() -> WorkoutSession {
        WorkoutSession(
            id: id,
            userId: user_id,
            workoutMode: workout_mode,
            completed: completed,
            completedRounds: completed_rounds,
            totalCompletedReps: total_completed_reps,
            totalWorkoutTimeSeconds: total_workout_time_seconds,
            progressPercentage: progress_percentage,
            exerciseReps: exercise_reps,
            exerciseTiming: exercise_timing,
            workoutStartedAt: workout_started_at,
            workoutEndedAt: workout_ended_at,
            isSynced: true // Sessions from cloud are already synced
        )
    }
}
