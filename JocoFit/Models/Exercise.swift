import Foundation

/// Categories for organizing exercises by muscle group
enum ExerciseCategory: String, Codable, CaseIterable {
    case upper = "Upper Body"
    case lower = "Lower Body"
    case core = "Core"
}

/// Represents a single exercise with its rep multiplier
struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let multiplier: Int
    let category: ExerciseCategory
    let description: String?

    init(id: UUID = UUID(), name: String, multiplier: Int, category: ExerciseCategory, description: String? = nil) {
        self.id = id
        self.name = name
        self.multiplier = multiplier
        self.category = category
        self.description = description
    }

    /// Default exercises available in the app
    static let defaults: [Exercise] = [
        Exercise(name: "Pull-ups", multiplier: 1, category: .upper, description: "Grip bar with palms facing away, pull chin above bar"),
        Exercise(name: "Standing Weight Press", multiplier: 1, category: .upper, description: "Press weight overhead from shoulder level"),
        Exercise(name: "Dips", multiplier: 2, category: .upper, description: "Lower body between parallel bars, push back up"),
        Exercise(name: "Push-ups", multiplier: 3, category: .upper, description: "Standard push-up with full range of motion"),
        Exercise(name: "Leg Lifts", multiplier: 3, category: .core, description: "Hang from bar, lift legs to parallel"),
        Exercise(name: "Sit-ups", multiplier: 4, category: .core, description: "Full sit-up with controlled movement"),
        Exercise(name: "Air Squats", multiplier: 5, category: .lower, description: "Bodyweight squat to parallel or below")
    ]

    /// Core exercises for the standard ladder workout (excludes Standing Weight Press and Leg Lifts)
    static let ladderDefaults: [Exercise] = [
        Exercise(name: "Pull-ups", multiplier: 1, category: .upper),
        Exercise(name: "Dips", multiplier: 2, category: .upper),
        Exercise(name: "Push-ups", multiplier: 3, category: .upper),
        Exercise(name: "Sit-ups", multiplier: 4, category: .core),
        Exercise(name: "Air Squats", multiplier: 5, category: .lower)
    ]

    /// Calculate reps for a given round number
    func repsForRound(_ round: Int) -> Int {
        return round * multiplier
    }

    /// Sanitized name for use in workout mode strings
    var sanitizedName: String {
        name.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
    }
}

// MARK: - Exercise Collections

extension Array where Element == Exercise {
    /// Filter out specific exercises by name
    func excluding(_ names: [String]) -> [Exercise] {
        filter { !names.contains($0.name) }
    }

    /// Total reps for all exercises at a given round
    func totalRepsForRound(_ round: Int) -> Int {
        reduce(0) { $0 + $1.repsForRound(round) }
    }

    /// Total multiplier sum (used for calculating total workout reps)
    var totalMultiplier: Int {
        reduce(0) { $0 + $1.multiplier }
    }
}
