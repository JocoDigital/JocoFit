import Foundation

/// App-wide constants
enum AppConstants {
    /// App name
    static let appName = "JocoFit"

    /// App bundle identifier
    static let bundleId = "com.jocodigital.jocofit"

    /// Workout constants
    enum Workout {
        /// Maximum round number in a ladder workout
        static let maxRound = 10

        /// Minimum round number in a ladder workout
        static let minRound = 1

        /// Total rounds in a full ladder (1→10→1)
        static let fullLadderRounds = 19

        /// Total rounds in ascending or descending mode
        static let halfLadderRounds = 10

        /// Sum of 1+2+...+10
        static let ascendingSum = 55

        /// Sum of 1+2+...+10+9+...+1 (excluding double 10)
        static let fullLadderSum = 100
    }

    /// API/Network constants
    enum API {
        /// Supabase table names
        static let workoutSessionsTable = "workout_sessions"
        static let workoutTemplatesTable = "workout_templates"
        static let exercisesTable = "exercises"
    }

    /// Storage keys for UserDefaults
    enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredTheme = "preferredTheme"
        static let lastWorkoutMode = "lastWorkoutMode"
    }

    /// Animation durations
    enum Animation {
        static let short = 0.2
        static let medium = 0.3
        static let long = 0.5
    }
}

/// Supabase configuration
enum SupabaseConfig {
    static let url = "https://jcobqznsqmmjpwirmhgf.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impjb2Jxem5zcW1tanB3aXJtaGdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2NzQxNTEsImV4cCI6MjA4NDI1MDE1MX0.iNsrHKQh3dVrTbz3WkbHfol__vPv5ACvtIP46yzN6bk"
}
