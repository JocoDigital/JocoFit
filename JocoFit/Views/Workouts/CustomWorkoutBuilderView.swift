import SwiftUI

struct CustomWorkoutBuilderView: View {
    @State private var selectedExercises: Set<String> = []
    @State private var orderedExercises: [Exercise] = []
    @State private var selectedProgression: ProgressionMode?
    @State private var navigateToWorkout = false
    @State private var showOrderingSheet = false

    private var exercises: [Exercise] {
        // Use ordered list if available, otherwise build from selection
        if !orderedExercises.isEmpty {
            return orderedExercises
        }
        return selectedExercises.compactMap { name in
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

                // Exercise Order Section (shown when exercises selected)
                if !selectedExercises.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Exercise Order")
                                .font(.headline)

                            Spacer()

                            Button {
                                showOrderingSheet = true
                            } label: {
                                Label("Reorder", systemImage: "arrow.up.arrow.down")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)

                        // Ordered list preview
                        VStack(spacing: 8) {
                            ForEach(Array(orderedExercises.enumerated()), id: \.element.id) { index, exercise in
                                HStack(spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .frame(width: 24, height: 24)
                                        .background(Color.blue.opacity(0.2))
                                        .clipShape(Circle())

                                    Text(exercise.name)
                                        .font(.subheadline)

                                    Spacer()

                                    Text("×\(exercise.multiplier)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Summary and Start Button
                if canStart {
                    VStack(spacing: 16) {
                        // Summary
                        HStack {
                            Text("Total Reps")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(configuration?.totalReps ?? 0)")
                                .fontWeight(.semibold)
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
        .sheet(isPresented: $showOrderingSheet) {
            ExerciseOrderingSheet(exercises: $orderedExercises)
        }
    }

    private func toggleExercise(_ name: String) {
        if selectedExercises.contains(name) {
            selectedExercises.remove(name)
            orderedExercises.removeAll { $0.name == name }
        } else {
            selectedExercises.insert(name)
            if let exercise = Exercise.defaults.first(where: { $0.name == name }) {
                orderedExercises.append(exercise)
            }
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
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .blue : .secondary)
                    Spacer()
                    Text("×\(exercise.multiplier)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.2))
                        .foregroundStyle(categoryColor)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)

                Text(exercise.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(exercise.category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .frame(height: 90)
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

// MARK: - Exercise Ordering Sheet

struct ExerciseOrderingSheet: View {
    @Binding var exercises: [Exercise]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(exercises) { exercise in
                        HStack(spacing: 12) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.secondary)

                            Text(exercise.name)
                                .font(.body)

                            Spacer()

                            Text("×\(exercise.multiplier)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove { from, to in
                        exercises.move(fromOffsets: from, toOffset: to)
                    }
                } header: {
                    Text("Drag to reorder exercises")
                } footer: {
                    Text("The order here determines which exercise you'll do first, second, etc. during each round of the ladder.")
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Exercise Order")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CustomWorkoutBuilderView()
    }
}
