import Foundation

/// Progression modes for ladder workouts
enum ProgressionMode: String, Codable, CaseIterable, Identifiable {
    case full = "full"
    case ascending = "ascending"
    case descending = "descending"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .full: return "Full Ladder"
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }

    var description: String {
        switch self {
        case .full: return "1→10→1 (19 rounds)"
        case .ascending: return "1→10 (10 rounds)"
        case .descending: return "10→1 (10 rounds)"
        }
    }

    /// Total rounds in this progression mode
    var totalRounds: Int {
        switch self {
        case .full: return 19
        case .ascending, .descending: return 10
        }
    }

    /// Sum of round numbers (1+2+...+10 = 55, or 1+2+...+10+9+...+1 = 100)
    /// Used to calculate total reps: multiplier × roundSum
    var roundSum: Int {
        switch self {
        case .full: return 100  // 1+2+3+4+5+6+7+8+9+10+9+8+7+6+5+4+3+2+1
        case .ascending, .descending: return 55  // 1+2+3+4+5+6+7+8+9+10
        }
    }

    /// Starting round number
    var startingRound: Int {
        switch self {
        case .full, .ascending: return 1
        case .descending: return 10
        }
    }
}

/// Preset workout configurations
enum PresetWorkout: String, CaseIterable, Identifiable {
    // Full set (all 5 exercises)
    case full
    case ascending
    case descending

    // No Dips (4 exercises)
    case fullNoDips = "full_no_dips"
    case ascendingNoDips = "ascending_no_dips"
    case descendingNoDips = "descending_no_dips"

    // No Squats (4 exercises)
    case fullNoSquats = "full_no_squats"
    case ascendingNoSquats = "ascending_no_squats"
    case descendingNoSquats = "descending_no_squats"

    // No Dips & No Squats (3 exercises)
    case fullNoDipsNoSquats = "full_no_dips_no_squats"
    case ascendingNoDipsNoSquats = "ascending_no_dips_no_squats"
    case descendingNoDipsNoSquats = "descending_no_dips_no_squats"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .full: return "Full Ladder"
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        case .fullNoDips: return "Full Ladder (No Dips)"
        case .ascendingNoDips: return "Ascending (No Dips)"
        case .descendingNoDips: return "Descending (No Dips)"
        case .fullNoSquats: return "Full Ladder (No Squats)"
        case .ascendingNoSquats: return "Ascending (No Squats)"
        case .descendingNoSquats: return "Descending (No Squats)"
        case .fullNoDipsNoSquats: return "Full Ladder (No Dips/Squats)"
        case .ascendingNoDipsNoSquats: return "Ascending (No Dips/Squats)"
        case .descendingNoDipsNoSquats: return "Descending (No Dips/Squats)"
        }
    }

    var progressionMode: ProgressionMode {
        switch self {
        case .full, .fullNoDips, .fullNoSquats, .fullNoDipsNoSquats:
            return .full
        case .ascending, .ascendingNoDips, .ascendingNoSquats, .ascendingNoDipsNoSquats:
            return .ascending
        case .descending, .descendingNoDips, .descendingNoSquats, .descendingNoDipsNoSquats:
            return .descending
        }
    }

    var exercises: [Exercise] {
        let base = Exercise.ladderDefaults
        switch self {
        case .full, .ascending, .descending:
            return base
        case .fullNoDips, .ascendingNoDips, .descendingNoDips:
            return base.excluding(["Dips"])
        case .fullNoSquats, .ascendingNoSquats, .descendingNoSquats:
            return base.excluding(["Air Squats"])
        case .fullNoDipsNoSquats, .ascendingNoDipsNoSquats, .descendingNoDipsNoSquats:
            return base.excluding(["Dips", "Air Squats"])
        }
    }

    var totalReps: Int {
        exercises.totalMultiplier * progressionMode.roundSum
    }

    /// Group presets by exercise variation for UI
    static var grouped: [(title: String, presets: [PresetWorkout])] {
        [
            ("Full Set (5 Exercises)", [.full, .ascending, .descending]),
            ("No Dips (4 Exercises)", [.fullNoDips, .ascendingNoDips, .descendingNoDips]),
            ("No Squats (4 Exercises)", [.fullNoSquats, .ascendingNoSquats, .descendingNoSquats]),
            ("No Dips & No Squats (3 Exercises)", [.fullNoDipsNoSquats, .ascendingNoDipsNoSquats, .descendingNoDipsNoSquats])
        ]
    }
}

/// Represents either a preset workout or a custom workout configuration
enum WorkoutConfiguration {
    case preset(PresetWorkout)
    case custom(exercises: [Exercise], progression: ProgressionMode, name: String?)

    var exercises: [Exercise] {
        switch self {
        case .preset(let preset): return preset.exercises
        case .custom(let exercises, _, _): return exercises
        }
    }

    var progressionMode: ProgressionMode {
        switch self {
        case .preset(let preset): return preset.progressionMode
        case .custom(_, let progression, _): return progression
        }
    }

    var totalReps: Int {
        exercises.totalMultiplier * progressionMode.roundSum
    }

    var modeString: String {
        switch self {
        case .preset(let preset):
            return preset.rawValue
        case .custom(let exercises, let progression, _):
            let exerciseNames = exercises.map { $0.sanitizedName }.joined(separator: "_")
            return "custom_\(exerciseNames)_\(progression.rawValue)"
        }
    }

    var displayName: String {
        switch self {
        case .preset(let preset):
            return preset.displayName
        case .custom(let exercises, let progression, let name):
            if let name = name {
                return name
            }
            let exerciseNames = exercises.map { $0.name }.joined(separator: ", ")
            return "\(exerciseNames) - \(progression.displayName)"
        }
    }
}
