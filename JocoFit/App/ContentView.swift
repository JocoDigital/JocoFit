import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if hasSeenOnboarding || authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView(onContinueAsGuest: {
                    hasSeenOnboarding = true
                })
            }
        }
        .task {
            // Configure auth with model context for sync
            authViewModel.configure(with: modelContext)
            await authViewModel.checkSession()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            WorkoutSelectionView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.run")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
