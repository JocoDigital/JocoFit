import SwiftUI

struct SessionDetailView: View {
    let session: WorkoutSession

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: session.completed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(session.completed ? .green : .orange)

                    Text(session.workoutTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(session.createdAt, format: .dateTime.weekday(.wide).month().day().year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(session.createdAt, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Main Stats
                HStack(spacing: 16) {
                    DetailStatCard(
                        title: "Duration",
                        value: session.formattedTime,
                        icon: "clock.fill",
                        color: .blue
                    )

                    DetailStatCard(
                        title: "Total Reps",
                        value: "\(session.totalCompletedReps)",
                        icon: "repeat",
                        color: .green
                    )
                }
                .padding(.horizontal)

                HStack(spacing: 16) {
                    DetailStatCard(
                        title: "Rounds",
                        value: "\(session.completedRounds)",
                        icon: "arrow.clockwise",
                        color: .purple
                    )

                    DetailStatCard(
                        title: "Progress",
                        value: String(format: "%.1f%%", session.progressPercentage),
                        icon: "chart.bar.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)

                // Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Status")
                        .font(.headline)

                    HStack {
                        Circle()
                            .fill(session.completed ? Color.green : Color.orange)
                            .frame(width: 12, height: 12)

                        Text(session.completed ? "Completed" : "Ended Early")
                            .fontWeight(.medium)

                        Spacer()

                        Text("Progress: \(String(format: "%.1f", session.progressPercentage))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Exercise Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercise Breakdown")
                        .font(.headline)

                    ForEach(Array(session.exerciseReps.keys.sorted()), id: \.self) { exercise in
                        HStack {
                            Text(exercise)
                                .fontWeight(.medium)

                            Spacer()

                            Text("\(session.exerciseReps[exercise] ?? 0) reps")
                                .foregroundStyle(.secondary)

                            if let timing = session.exerciseTiming[exercise] {
                                Text(formatTime(timing))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)

                // Timing Details
                if let startTime = session.workoutStartedAt as Date?,
                   let endTime = session.workoutEndedAt {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Timing")
                            .font(.headline)

                        VStack(spacing: 8) {
                            HStack {
                                Text("Started")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(startTime, format: .dateTime.hour().minute().second())
                            }

                            Divider()

                            HStack {
                                Text("Ended")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(endTime, format: .dateTime.hour().minute().second())
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Detail Stat Card

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
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

#Preview {
    NavigationStack {
        SessionDetailView(session: WorkoutSession(
            userId: UUID(),
            workoutMode: "full",
            completed: true,
            completedRounds: 19,
            totalCompletedReps: 1500,
            totalWorkoutTimeSeconds: 2547,
            progressPercentage: 100.0,
            exerciseReps: [
                "Pull-ups": 100,
                "Dips": 200,
                "Push-ups": 300,
                "Sit-ups": 400,
                "Air Squats": 500
            ],
            exerciseTiming: [
                "Pull-ups": 300,
                "Dips": 400,
                "Push-ups": 500,
                "Sit-ups": 600,
                "Air Squats": 747
            ]
        ))
    }
}
