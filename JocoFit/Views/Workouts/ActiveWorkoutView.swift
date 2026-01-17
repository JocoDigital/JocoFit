import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = WorkoutViewModel()
    @State private var showEndWorkoutConfirmation = false
    @State private var showSummary = false

    // Initialize with preset
    let preset: PresetWorkout?
    let configuration: WorkoutConfiguration?

    init(preset: PresetWorkout) {
        self.preset = preset
        self.configuration = nil
    }

    init(configuration: WorkoutConfiguration) {
        self.preset = nil
        self.configuration = configuration
    }

    var body: some View {
        Group {
            if viewModel.isComplete {
                WorkoutSummaryView(viewModel: viewModel)
            } else if viewModel.isActive {
                activeWorkoutContent
            } else {
                preWorkoutContent
            }
        }
        .navigationBarBackButtonHidden(viewModel.isActive)
        .toolbar {
            if viewModel.isActive {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") {
                        showEndWorkoutConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .confirmationDialog(
            "End Workout Early?",
            isPresented: $showEndWorkoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Workout", role: .destructive) {
                viewModel.endWorkoutEarly()
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Your progress will be saved, but the workout will be marked as incomplete.")
        }
        .onAppear {
            configureWorkout()
            // Keep screen on during workout
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
        }
        .onDisappear {
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
    }

    // MARK: - Pre-Workout Content

    private var preWorkoutContent: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text(workoutTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("\(viewModel.totalReps) total reps")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Exercise list
            VStack(spacing: 12) {
                ForEach(viewModel.exercises) { exercise in
                    HStack {
                        Text(exercise.name)
                        Spacer()
                        Text("×\(exercise.multiplier)")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                viewModel.startWorkout()
            } label: {
                Text("Start Workout")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Active Workout Content

    private var activeWorkoutContent: some View {
        VStack(spacing: 0) {
            // Timer Bar
            HStack {
                Text(viewModel.formattedTime)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.semibold)

                Spacer()

                Text("\(Int(viewModel.progressPercentage))%")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))

            // Progress Bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(.blue)
                    .frame(width: geometry.size.width * viewModel.progressPercentage / 100)
            }
            .frame(height: 4)

            Spacer()

            // Current Exercise Display
            VStack(spacing: 24) {
                // Round and Exercise Info
                HStack {
                    Text(viewModel.roundDisplay)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())

                    Text(viewModel.exerciseDisplay)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                }

                // Exercise Name
                Text(viewModel.currentExercise?.name ?? "")
                    .font(.system(size: 36, weight: .bold))
                    .multilineTextAlignment(.center)

                // Rep Count
                VStack(spacing: 8) {
                    Text("\(viewModel.currentReps)")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)

                    Text("reps")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                // Next Exercise Preview
                if let nextExercise = viewModel.nextExercise {
                    VStack(spacing: 4) {
                        Text("Next:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(nextExercise.name) - \(viewModel.nextReps) reps")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)
                }
            }

            Spacer()

            // Complete Set Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.completeCurrentSet()
                }
            } label: {
                Text("Done - Next Exercise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Helpers

    private var workoutTitle: String {
        if let preset = preset {
            return preset.displayName
        }
        return configuration?.displayName ?? "Custom Workout"
    }

    private func configureWorkout() {
        if let preset = preset {
            viewModel.configure(with: preset)
        } else if let config = configuration {
            viewModel.configure(with: config)
        }
    }
}

#Preview("Pre-workout") {
    NavigationStack {
        ActiveWorkoutView(preset: .full)
            .environmentObject(AuthViewModel())
    }
}
