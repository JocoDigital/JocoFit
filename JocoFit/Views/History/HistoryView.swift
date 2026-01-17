import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
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
                await viewModel.refresh(userId: authViewModel.userId, isAuthenticated: authViewModel.isAuthenticated)
            }
            .task {
                viewModel.configure(with: modelContext)
                await viewModel.refresh(userId: authViewModel.userId, isAuthenticated: authViewModel.isAuthenticated)
            }
            .confirmationDialog(
                "Delete Workout?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let session = sessionToDelete {
                        Task {
                            await viewModel.deleteSession(session, userId: authViewModel.userId)
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

            if !authViewModel.isAuthenticated {
                VStack(spacing: 8) {
                    Text("Sign in to back up and sync your workouts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)
            }
        }
        .padding()
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            // Sign-in banner for guests
            if !authViewModel.isAuthenticated {
                Section {
                    SignInBanner()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Stats Header
            if let stats = viewModel.stats {
                Section {
                    StatsHeaderCard(stats: stats)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Filter indicator
            if let filter = viewModel.selectedModeFilter {
                Section {
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
                }
            }

            // Sessions
            Section {
                ForEach(viewModel.filteredSessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session, onDelete: {
                        await viewModel.deleteSession(session, userId: authViewModel.userId)
                    })) {
                        HistorySessionCard(session: session)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            sessionToDelete = session
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
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

// MARK: - Sign In Banner

struct SignInBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sign in to back up and sync")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Your workouts are saved on this device. Sign in to back them up and access from anywhere.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - History Session Card

struct HistorySessionCard: View {
    let session: WorkoutSession

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(session.workoutTitle)
                            .font(.headline)

                        // Show sync status icon
                        if !session.isSynced {
                            Image(systemName: "icloud.slash")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

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
        .background(Color.secondaryBackground)
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
