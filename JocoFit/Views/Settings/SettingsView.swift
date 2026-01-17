import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section("Account") {
                    if let email = authViewModel.userEmail {
                        HStack {
                            Label("Email", systemImage: "envelope")
                            Spacer()
                            Text(email)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                // App Info Section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://jocodigital.com")!) {
                        Label("Website", systemImage: "globe")
                    }

                    Link(destination: URL(string: "mailto:support@jocodigital.com")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }

                // Legal Section
                Section("Legal") {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                // Data Management
                Section("Data") {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Manage Data", systemImage: "externaldrive")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Sign Out?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to access your workouts.")
            }
        }
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Last updated: January 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Group {
                    Text("Information We Collect")
                        .font(.headline)

                    Text("JocoFit collects the following information to provide our services:")
                    Text("• Email address for account authentication")
                    Text("• Workout data including exercises, reps, and timing")
                    Text("• App usage analytics (anonymous)")

                    Text("How We Use Your Information")
                        .font(.headline)
                        .padding(.top)

                    Text("Your information is used to:")
                    Text("• Provide and improve our workout tracking service")
                    Text("• Sync your workout history across devices")
                    Text("• Send important account notifications")

                    Text("Data Storage")
                        .font(.headline)
                        .padding(.top)

                    Text("Your data is securely stored using Supabase infrastructure with encryption at rest and in transit.")
                }
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Last updated: January 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Group {
                    Text("Acceptance of Terms")
                        .font(.headline)

                    Text("By using JocoFit, you agree to these terms of service.")

                    Text("Use of Service")
                        .font(.headline)
                        .padding(.top)

                    Text("JocoFit is a personal fitness tracking application. You are responsible for your own physical health and safety when performing any exercises tracked by this app.")

                    Text("Disclaimer")
                        .font(.headline)
                        .padding(.top)

                    Text("JocoFit is provided \"as is\" without warranty. Consult a healthcare provider before starting any exercise program.")
                }
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        List {
            Section {
                Text("Your workout data is synced to the cloud and stored securely. You can delete all your data at any time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    if isDeleting {
                        HStack {
                            ProgressView()
                            Text("Deleting...")
                        }
                    } else {
                        Label("Delete All Workout Data", systemImage: "trash")
                    }
                }
                .disabled(isDeleting)
            } footer: {
                Text("This will permanently delete all your workout history. This action cannot be undone.")
            }
        }
        .navigationTitle("Manage Data")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete All Data?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                // TODO: Implement data deletion
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your workout history and cannot be undone.")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
