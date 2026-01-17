import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue)

                        Text("JocoFit")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Your personal workout companion")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Login Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            #if os(iOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled()

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)

                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Task {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        } label: {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Sign In")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(.footnote)
                    }
                    .padding(.horizontal, 32)

                    Divider()
                        .padding(.horizontal, 32)

                    // Sign Up
                    VStack(spacing: 8) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Create Account") {
                            showSignUp = true
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    email = ""
                    password = ""
                }
            }
        }
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var emailSent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .padding(.horizontal, 32)

                if let message = authViewModel.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(emailSent ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        await authViewModel.resetPassword(email: email)
                        emailSent = true
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Send Reset Link")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || authViewModel.isLoading)
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Reset Password")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
