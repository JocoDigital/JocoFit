import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @State private var showDeleteConfirmation = false
    @State private var sessionToDelete: WorkoutSession?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    ProgressView("Loading history...")
                } else if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("All Workouts") {
                            viewModel.clearFilter()
                        }

                        Divider()

                        ForEach(viewModel.uniqueModes, id: \.self) { mode in
                            Button(formatModeName(mode)) {
                                viewModel.setFilter(mode)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.refresh()
            }
            .confirmationDialog(
                "Delete Workout?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let session = sessionToDelete {
                        Task {
                            await viewModel.deleteSession(session)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    sessionToDelete = nil
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Complete your first workout to see it here!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - History List

    private var historyList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats Header
                if let stats = viewModel.stats {
                    StatsHeaderCard(stats: stats)
                        .padding(.horizontal)
                }

                // Filter indicator
                if let filter = viewModel.selectedModeFilter {
                    HStack {
                        Text("Filtered: \(formatModeName(filter))")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Clear") {
                            viewModel.clearFilter()
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                }

                // Sessions
                ForEach(viewModel.filteredSessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        HistorySessionCard(session: session)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .contextMenu {
                        Button(role: .destructive) {
                            sessionToDelete = session
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func formatModeName(_ mode: String) -> String {
        if mode.hasPrefix("custom_") {
            return "Custom Workout"
        }
        return PresetWorkout(rawValue: mode)?.displayName ?? mode.capitalized
    }
}

// MARK: - Stats Header Card

struct StatsHeaderCard: View {
    let stats: WorkoutStats

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overview")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 0) {
                StatColumn(value: "\(stats.totalSessions)", label: "Total")
                Divider().frame(height: 40)
                StatColumn(value: "\(stats.completedSessions)", label: "Completed")
                Divider().frame(height: 40)
                StatColumn(value: stats.formattedCompletionRate, label: "Rate")
                Divider().frame(height: 40)
                StatColumn(value: stats.formattedBestTime ?? "--:--", label: "Best Time")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatColumn: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - History Session Card

struct HistorySessionCard: View {
    let session: WorkoutSession

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workoutTitle)
                        .font(.headline)

                    Text(session.createdAt, format: .dateTime.month().day().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadge(completed: session.completed)
            }

            HStack(spacing: 20) {
                Label(session.formattedTime, systemImage: "clock")
                Label("\(session.totalCompletedReps) reps", systemImage: "repeat")
                Label("\(session.completedRounds) rounds", systemImage: "arrow.clockwise")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Progress bar
            ProgressView(value: session.progressPercentage, total: 100)
                .tint(session.completed ? .green : .orange)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatusBadge: View {
    let completed: Bool

    var body: some View {
        Text(completed ? "Completed" : "Partial")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(completed ? .green : .orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background((completed ? Color.green : Color.orange).opacity(0.1))
            .clipShape(Capsule())
    }
}

#Preview {
    HistoryView()
}
