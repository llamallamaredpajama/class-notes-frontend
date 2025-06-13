import SwiftUI

/// Test view for verifying conditional authentication behavior
struct AuthenticationTestView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Environment(\.authenticationService) private var authService

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Authentication Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Show which environment we're in
                HStack {
                    Image(systemName: environmentIcon)
                        .foregroundColor(environmentColor)
                    Text(environmentText)
                        .font(.headline)
                        .foregroundColor(environmentColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(environmentColor.opacity(0.1))
                .cornerRadius(20)
            }

            // Authentication Status
            VStack(spacing: 15) {
                StatusRow(
                    title: "Authentication Status",
                    value: authViewModel.isAuthenticated ? "Authenticated" : "Not Authenticated",
                    isPositive: authViewModel.isAuthenticated
                )

                if let user = authViewModel.currentUser {
                    StatusRow(title: "Email", value: user.email, isPositive: true)
                    StatusRow(title: "Name", value: user.displayName, isPositive: true)
                    StatusRow(title: "Provider", value: user.authProvider, isPositive: true)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)

            // Actions
            VStack(spacing: 15) {
                if !authViewModel.isAuthenticated {
                    Button(action: signIn) {
                        Label("Sign In", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading)
                } else {
                    Button(action: signOut) {
                        Label("Sign Out", systemImage: "person.badge.minus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading)
                }

                Button(action: checkStatus) {
                    Label("Check Status", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal)

            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }

            // Loading Indicator
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Auth Test")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Computed Properties

    private var environmentIcon: String {
        #if targetEnvironment(simulator)
            return "ipad.gen2"
        #else
            return "iphone"
        #endif
    }

    private var environmentColor: Color {
        #if targetEnvironment(simulator)
            return .orange
        #else
            return .green
        #endif
    }

    private var environmentText: String {
        #if targetEnvironment(simulator)
            return "Simulator (Mock Auth)"
        #else
            return "Physical Device (Real Auth)"
        #endif
    }

    // MARK: - Actions

    private func signIn() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.signIn()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func signOut() {
        isLoading = true
        errorMessage = nil

        Task {
            await authService.signOut()
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func checkStatus() {
        Task {
            await authViewModel.checkAuthenticationStatus()
        }
    }
}

// MARK: - Supporting Views

struct StatusRow: View {
    let title: String
    let value: String
    let isPositive: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? .green : .red)
        }
    }
}

// MARK: - Preview

struct AuthenticationTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AuthenticationTestView()
                .environmentObject(
                    AuthenticationViewModel(authService: MockAuthenticationService()))
        }
    }
}
