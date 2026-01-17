import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var stats: WorkoutStats?
    @State private var recentSessions: [WorkoutSession] = []
    @State private var isLoading = true

    private let supabase = SupabaseService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back!")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text("Ready to work out?")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Quick Start Card
                    NavigationLink(destination: WorkoutSelectionView()) {
                        QuickStartCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Stats Overview
                    if let stats = stats {
                        StatsOverviewCard(stats: stats)
                            .padding(.horizontal)
                    }

                    // Recent Workouts
                    if !recentSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Workouts")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(recentSessions.prefix(3)) { session in
                                RecentSessionRow(session: session)
                                    .padding(.horizontal)
                            }

                            NavigationLink(destination: HistoryView()) {
                                Text("View All History")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("JocoFit")
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
        }
    }

    private func loadData() async {
        isLoading = true
        do {
            stats = try await supabase.fetchWorkoutStats()
            recentSessions = try await supabase.fetchWorkoutSessions(limit: 5)
        } catch {
            // Handle error silently for home screen
        }
        isLoading = false
    }
}

// MARK: - Quick Start Card

struct QuickStartCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text("Start Workout")
                    .font(.headline)

                Text("Choose from presets or build your own")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stats Overview Card

struct StatsOverviewCard: View {
    let stats: WorkoutStats

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 20) {
                StatItem(
                    title: "Workouts",
                    value: "\(stats.totalSessions)",
                    icon: "flame.fill",
                    color: .orange
                )

                StatItem(
                    title: "Completed",
                    value: stats.formattedCompletionRate,
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatItem(
                    title: "Total Reps",
                    value: formatNumber(stats.totalReps),
                    icon: "repeat",
                    color: .blue
                )

                StatItem(
                    title: "Time",
                    value: stats.formattedTotalTime,
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}

struct StatItem: View {
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
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Session Row

struct RecentSessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(session.completed ? Color.green : Color.orange)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.workoutTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(session.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.totalCompletedReps) reps")
                    .font(.subheadline)

                Text(session.formattedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
