import Foundation
import SwiftData

/// A saved custom workout configuration
@Model
final class WorkoutTemplate {
    var id: UUID
    var userId: UUID
    var name: String
    var exerciseNamesData: Data? // JSON encoded [String]
    var progressionMode: String
    var isFavorite: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        exerciseNames: [String],
        progressionMode: ProgressionMode,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.exerciseNamesData = try? JSONEncoder().encode(exerciseNames)
        self.progressionMode = progressionMode.rawValue
        self.isFavorite = isFavorite
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    var exerciseNames: [String] {
        get {
            guard let data = exerciseNamesData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            exerciseNamesData = try? JSONEncoder().encode(newValue)
        }
    }

    var progression: ProgressionMode {
        ProgressionMode(rawValue: progressionMode) ?? .full
    }

    var exercises: [Exercise] {
        exerciseNames.compactMap { name in
            Exercise.defaults.first { $0.name == name }
        }
    }

    var configuration: WorkoutConfiguration {
        .custom(exercises: exercises, progression: progression, name: name)
    }

    var totalReps: Int {
        configuration.totalReps
    }
}

// MARK: - Supabase DTO

struct WorkoutTemplateDTO: Codable {
    let id: UUID
    let user_id: UUID
    let name: String
    let exercises: [String]
    let progression_mode: String
    let is_favorite: Bool
    let created_at: Date?

    init(from template: WorkoutTemplate) {
        self.id = template.id
        self.user_id = template.userId
        self.name = template.name
        self.exercises = template.exerciseNames
        self.progression_mode = template.progressionMode
        self.is_favorite = template.isFavorite
        self.created_at = template.createdAt
    }

    func toTemplate() -> WorkoutTemplate {
        let template = WorkoutTemplate(
            id: id,
            userId: user_id,
            name: name,
            exerciseNames: exercises,
            progressionMode: ProgressionMode(rawValue: progression_mode) ?? .full,
            isFavorite: is_favorite
        )
        return template
    }
}
