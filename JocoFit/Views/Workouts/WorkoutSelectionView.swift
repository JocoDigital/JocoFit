import SwiftUI

struct WorkoutSelectionView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Workout Type", selection: $selectedTab) {
                    Text("Presets").tag(0)
                    Text("Custom").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                Group {
                    if selectedTab == 0 {
                        PresetWorkoutsView()
                    } else {
                        CustomWorkoutBuilderView()
                    }
                }
            }
            .navigationTitle("Workouts")
        }
    }
}

// MARK: - Preset Workouts View

struct PresetWorkoutsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(PresetWorkout.grouped, id: \.title) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.title)
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(group.presets) { preset in
                            NavigationLink(destination: ActiveWorkoutView(preset: preset)) {
                                PresetWorkoutCard(preset: preset)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Preset Workout Card

struct PresetWorkoutCard: View {
    let preset: PresetWorkout

    var body: some View {
        HStack(spacing: 16) {
            // Icon based on progression type
            Image(systemName: progressionIcon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(progressionColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(preset.displayName)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label("\(preset.exercises.count) exercises", systemImage: "figure.walk")
                    Label("\(preset.totalReps) reps", systemImage: "repeat")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var progressionIcon: String {
        switch preset.progressionMode {
        case .full: return "arrow.up.arrow.down"
        case .ascending: return "arrow.up.right"
        case .descending: return "arrow.down.right"
        }
    }

    private var progressionColor: Color {
        switch preset.progressionMode {
        case .full: return .blue
        case .ascending: return .green
        case .descending: return .orange
        }
    }
}

#Preview {
    WorkoutSelectionView()
}
