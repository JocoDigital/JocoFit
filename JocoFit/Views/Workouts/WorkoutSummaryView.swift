import SwiftUI

struct WorkoutSummaryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let viewModel: WorkoutViewModel
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var bestSession: WorkoutSession?
    @State private var isNewPersonalBest = false
    @State private var savedLocally = false

    private let supabase = SupabaseService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: viewModel.isEndedEarly ? "flag.checkered" : "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(viewModel.isEndedEarly ? .orange : .yellow)

                    Text(viewModel.isEndedEarly ? "Workout Ended" : "Workout Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if isNewPersonalBest && !viewModel.isEndedEarly {
                        Text("New Personal Best!")
                            .font(.headline)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 20)

                // Main Stats
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                        SummaryStatCard(
                            title: "Time",
                            value: viewModel.formattedTime,
                            icon: "clock.fill",
                            color: .blue
                        )

                        SummaryStatCard(
                            title: "Reps",
                            value: "\(viewModel.totalCompletedReps)",
                            icon: "repeat",
                            color: .green
                        )
                    }

                    HStack(spacing: 24) {
                        SummaryStatCard(
                            title: "Rounds",
                            value: "\(viewModel.completedRounds)",
                            icon: "arrow.clockwise",
                            color: .purple
                        )

                        SummaryStatCard(
                            title: "Progress",
                            value: String(format: "%.1f%%", viewModel.progressPercentage),
                            icon: "chart.line.uptrend.xyaxis",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)

                // Personal Best Comparison
                if let best = bestSession, !viewModel.isEndedEarly {
                    PersonalBestComparison(
                        currentTime: viewModel.totalWorkoutTimeSeconds,
                        bestTime: best.totalWorkoutTimeSeconds,
                        isNewBest: isNewPersonalBest
                    )
                    .padding(.horizontal)
                }

                // Exercise Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercise Breakdown")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(viewModel.exerciseBreakdown, id: \.exercise) { item in
                        ExerciseBreakdownRow(
                            exercise: item.exercise,
                            reps: item.reps,
                            time: viewModel.formatTime(item.time)
                        )
                        .padding(.horizontal)
                    }
                }

                // Save Status / Sign In Prompt
                if let error = saveError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal)
                } else if savedLocally && !authViewModel.isAuthenticated {
                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Saved to this device")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)

                        HStack(spacing: 8) {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundStyle(.blue)
                            Text("Sign in to back up and sync your workouts")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Done Button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await saveSession()
            await checkPersonalBest()
        }
    }

    private func saveSession() async {
        isSaving = true

        // Create session (userId will be nil for guests)
        let session = viewModel.createSession(userId: authViewModel.userId)

        // Always save locally first via SwiftData
        let localStorage = LocalStorageService(modelContext: modelContext)
        localStorage.saveSession(session)
        savedLocally = true

        // If authenticated, also sync to cloud
        if authViewModel.isAuthenticated {
            do {
                try await supabase.saveWorkoutSession(session)
                localStorage.markAsSynced([session.id])
            } catch {
                // Local save succeeded, cloud will sync later
                saveError = "Saved locally. Cloud sync will retry later."
            }
        }

        isSaving = false
    }

    private func checkPersonalBest() async {
        guard !viewModel.isEndedEarly,
              let modeString = viewModel.configuration?.modeString else { return }

        do {
            bestSession = try await supabase.fetchBestSession(forMode: modeString)

            // Check if current is better than best (or if this is first completed workout)
            if let best = bestSession {
                isNewPersonalBest = viewModel.totalWorkoutTimeSeconds < best.totalWorkoutTimeSeconds
            } else {
                isNewPersonalBest = true // First completed workout for this mode
            }
        } catch {
            // Silently fail - not critical
        }
    }
}

// MARK: - Summary Stat Card

struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Personal Best Comparison

struct PersonalBestComparison: View {
    let currentTime: Int
    let bestTime: Int
    let isNewBest: Bool

    private var timeDifference: Int {
        currentTime - bestTime
    }

    private var formattedDifference: String {
        let absSeconds = abs(timeDifference)
        let minutes = absSeconds / 60
        let seconds = absSeconds % 60
        let prefix = timeDifference > 0 ? "+" : "-"
        return "\(prefix)\(String(format: "%02d:%02d", minutes, seconds))"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Personal Best Comparison")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                VStack {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatTime(currentTime))
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Text("vs")
                    .foregroundStyle(.secondary)

                VStack {
                    Text("Best")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatTime(bestTime))
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text(formattedDifference)
                    .font(.headline)
                    .foregroundStyle(isNewBest ? .green : .red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((isNewBest ? Color.green : Color.red).opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Exercise Breakdown Row

struct ExerciseBreakdownRow: View {
    let exercise: String
    let reps: Int
    let time: String

    var body: some View {
        HStack {
            Text(exercise)
                .fontWeight(.medium)

            Spacer()

            Text("\(reps) reps")
                .foregroundStyle(.secondary)

            Text(time)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding()
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        let vm = WorkoutViewModel()
        // Simulate completed workout state for preview
        WorkoutSummaryView(viewModel: vm)
            .environmentObject(AuthViewModel())
    }
}
