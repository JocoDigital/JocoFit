import SwiftUI

struct CustomWorkoutBuilderView: View {
    @State private var selectedExercises: Set<String> = []
    @State private var selectedProgression: ProgressionMode?
    @State private var navigateToWorkout = false

    private var exercises: [Exercise] {
        selectedExercises.compactMap { name in
            Exercise.defaults.first { $0.name == name }
        }.sorted { $0.multiplier < $1.multiplier }
    }

    private var configuration: WorkoutConfiguration? {
        guard !exercises.isEmpty, let progression = selectedProgression else { return nil }
        return .custom(exercises: exercises, progression: progression, name: nil)
    }

    private var canStart: Bool {
        !selectedExercises.isEmpty && selectedProgression != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Exercise Selection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Select Exercises")
                            .font(.headline)

                        Spacer()

                        Text("\(selectedExercises.count) selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Exercise.defaults) { exercise in
                            ExerciseSelectionCard(
                                exercise: exercise,
                                isSelected: selectedExercises.contains(exercise.name)
                            ) {
                                toggleExercise(exercise.name)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Progression Mode Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progression Mode")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(ProgressionMode.allCases) { mode in
                        ProgressionModeCard(
                            mode: mode,
                            isSelected: selectedProgression == mode,
                            totalReps: calculateTotalReps(for: mode)
                        ) {
                            selectedProgression = mode
                        }
                        .padding(.horizontal)
                    }
                }

                // Summary and Start Button
                if canStart {
                    VStack(spacing: 16) {
                        // Summary
                        VStack(spacing: 8) {
                            HStack {
                                Text("Total Reps")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(configuration?.totalReps ?? 0)")
                                    .fontWeight(.semibold)
                            }

                            HStack {
                                Text("Exercises")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(exercises.map { $0.name }.joined(separator: ", "))
                                    .font(.caption)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Start Button
                        NavigationLink(destination: ActiveWorkoutView(configuration: configuration!)) {
                            Text("Start Workout")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }

    private func toggleExercise(_ name: String) {
        if selectedExercises.contains(name) {
            selectedExercises.remove(name)
        } else {
            selectedExercises.insert(name)
        }
    }

    private func calculateTotalReps(for mode: ProgressionMode) -> Int {
        exercises.totalMultiplier * mode.roundSum
    }
}

// MARK: - Exercise Selection Card

struct ExerciseSelectionCard: View {
    let exercise: Exercise
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .blue : .secondary)
                    Spacer()
                    Text("×\(exercise.multiplier)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor.opacity(0.2))
                        .foregroundStyle(categoryColor)
                        .clipShape(Capsule())
                }

                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(exercise.category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var categoryColor: Color {
        switch exercise.category {
        case .upper: return .blue
        case .lower: return .green
        case .core: return .orange
        }
    }
}

// MARK: - Progression Mode Card

struct ProgressionModeCard: View {
    let mode: ProgressionMode
    let isSelected: Bool
    let totalReps: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if totalReps > 0 {
                    Text("\(totalReps) reps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CustomWorkoutBuilderView()
    }
}
