import Foundation
import SwiftUI
import Combine

/// Main view model for managing active workout state and progression
@Observable
final class WorkoutViewModel {
    // MARK: - Configuration

    private(set) var configuration: WorkoutConfiguration?
    private(set) var exercises: [Exercise] = []
    private(set) var progressionMode: ProgressionMode = .full

    // MARK: - Workout State

    private(set) var isActive: Bool = false
    private(set) var isComplete: Bool = false
    private(set) var isEndedEarly: Bool = false

    private(set) var currentRound: Int = 1
    private(set) var currentExerciseIndex: Int = 0
    private(set) var isDescending: Bool = false // For full ladder mode

    // MARK: - Progress Tracking

    private(set) var completedRounds: Int = 0
    private(set) var completedExercisesInCurrentRound: Int = 0
    private(set) var totalCompletedReps: Int = 0
    private(set) var exerciseReps: [String: Int] = [:]
    private(set) var exerciseTiming: [String: Int] = [:]

    // MARK: - Timing

    private(set) var workoutStartTime: Date?
    private(set) var currentExerciseStartTime: Date?
    private(set) var totalWorkoutTimeSeconds: Int = 0

    private var timer: Timer?

    // MARK: - Computed Properties

    var currentExercise: Exercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var currentReps: Int {
        guard let exercise = currentExercise else { return 0 }
        return exercise.repsForRound(currentRound)
    }

    var nextExercise: Exercise? {
        let nextIndex = currentExerciseIndex + 1
        if nextIndex < exercises.count {
            return exercises[nextIndex]
        } else if !isLastRound {
            return exercises.first
        }
        return nil
    }

    var nextReps: Int {
        guard let exercise = nextExercise else { return 0 }
        let nextRound = nextRoundNumber
        return exercise.repsForRound(nextRound)
    }

    var totalReps: Int {
        configuration?.totalReps ?? 0
    }

    var totalRounds: Int {
        progressionMode.totalRounds
    }

    var progressPercentage: Double {
        let totalExercises = totalRounds * exercises.count
        guard totalExercises > 0 else { return 0 }

        let completedExercises = completedRounds * exercises.count + completedExercisesInCurrentRound
        return Double(completedExercises) / Double(totalExercises) * 100
    }

    var formattedTime: String {
        let minutes = totalWorkoutTimeSeconds / 60
        let seconds = totalWorkoutTimeSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var roundDisplay: String {
        "Round \(currentRound)"
    }

    var exerciseDisplay: String {
        "Exercise \(currentExerciseIndex + 1)/\(exercises.count)"
    }

    var isLastRound: Bool {
        switch progressionMode {
        case .ascending:
            return currentRound >= 10
        case .descending:
            return currentRound <= 1
        case .full:
            return isDescending && currentRound <= 1
        }
    }

    var isLastExerciseInRound: Bool {
        currentExerciseIndex >= exercises.count - 1
    }

    private var nextRoundNumber: Int {
        if isLastExerciseInRound {
            return calculateNextRound()
        }
        return currentRound
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Workout Setup

    func configure(with preset: PresetWorkout) {
        configure(with: .preset(preset))
    }

    func configure(with config: WorkoutConfiguration) {
        self.configuration = config
        self.exercises = config.exercises
        self.progressionMode = config.progressionMode

        // Initialize exercise tracking
        for exercise in exercises {
            exerciseReps[exercise.name] = 0
            exerciseTiming[exercise.name] = 0
        }
    }

    // MARK: - Workout Control

    func startWorkout() {
        guard !exercises.isEmpty else { return }

        isActive = true
        isComplete = false
        isEndedEarly = false
        isDescending = false

        currentRound = progressionMode.startingRound
        currentExerciseIndex = 0
        completedRounds = 0
        completedExercisesInCurrentRound = 0
        totalCompletedReps = 0
        totalWorkoutTimeSeconds = 0

        workoutStartTime = Date()
        currentExerciseStartTime = Date()

        startTimer()
    }

    func completeCurrentSet() {
        guard isActive, let exercise = currentExercise else { return }

        // Record completed reps
        let reps = currentReps
        totalCompletedReps += reps
        exerciseReps[exercise.name, default: 0] += reps

        // Record timing for this exercise set
        if let startTime = currentExerciseStartTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            exerciseTiming[exercise.name, default: 0] += elapsed
        }

        // Move to next exercise
        advanceToNextExercise()
    }

    func endWorkoutEarly() {
        guard isActive else { return }

        isEndedEarly = true
        finishWorkout()
    }

    func reset() {
        stopTimer()

        configuration = nil
        exercises = []
        progressionMode = .full

        isActive = false
        isComplete = false
        isEndedEarly = false
        isDescending = false

        currentRound = 1
        currentExerciseIndex = 0
        completedRounds = 0
        completedExercisesInCurrentRound = 0
        totalCompletedReps = 0
        totalWorkoutTimeSeconds = 0

        exerciseReps = [:]
        exerciseTiming = [:]

        workoutStartTime = nil
        currentExerciseStartTime = nil
    }

    // MARK: - Private Methods

    private func advanceToNextExercise() {
        currentExerciseIndex += 1
        completedExercisesInCurrentRound += 1
        currentExerciseStartTime = Date()

        // Check if we've completed all exercises in the round
        if currentExerciseIndex >= exercises.count {
            completeRound()
        }
    }

    private func completeRound() {
        completedRounds += 1
        currentExerciseIndex = 0
        completedExercisesInCurrentRound = 0

        let nextRound = calculateNextRound()

        // Check if workout is complete
        if isWorkoutComplete(afterMovingTo: nextRound) {
            finishWorkout()
        } else {
            currentRound = nextRound
        }
    }

    private func calculateNextRound() -> Int {
        switch progressionMode {
        case .ascending:
            return currentRound + 1
        case .descending:
            return currentRound - 1
        case .full:
            if !isDescending {
                // Still ascending
                if currentRound >= 10 {
                    // Switch to descending phase
                    isDescending = true
                    return 9 // Skip double 10
                }
                return currentRound + 1
            } else {
                // Descending phase
                return currentRound - 1
            }
        }
    }

    private func isWorkoutComplete(afterMovingTo nextRound: Int) -> Bool {
        switch progressionMode {
        case .ascending:
            return nextRound > 10
        case .descending:
            return nextRound < 1
        case .full:
            return isDescending && nextRound < 1
        }
    }

    private func finishWorkout() {
        stopTimer()
        isActive = false
        isComplete = true
    }

    // MARK: - Timer Management

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.totalWorkoutTimeSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Session Creation

    func createSession(userId: UUID) -> WorkoutSession {
        WorkoutSession(
            userId: userId,
            workoutMode: configuration?.modeString ?? "unknown",
            completed: !isEndedEarly,
            completedRounds: completedRounds,
            totalCompletedReps: totalCompletedReps,
            totalWorkoutTimeSeconds: totalWorkoutTimeSeconds,
            progressPercentage: progressPercentage,
            exerciseReps: exerciseReps,
            exerciseTiming: exerciseTiming,
            workoutStartedAt: workoutStartTime ?? Date(),
            workoutEndedAt: Date()
        )
    }
}

// MARK: - Statistics Helper

extension WorkoutViewModel {
    /// Get exercise breakdown for summary display
    var exerciseBreakdown: [(exercise: String, reps: Int, time: Int)] {
        exercises.map { exercise in
            (
                exercise: exercise.name,
                reps: exerciseReps[exercise.name] ?? 0,
                time: exerciseTiming[exercise.name] ?? 0
            )
        }
    }

    /// Format seconds as MM:SS
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
