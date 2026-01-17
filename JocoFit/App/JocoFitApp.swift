import SwiftUI
import Supabase

@main
struct JocoFitApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(authViewModel)
        }
        #endif
    }
}
