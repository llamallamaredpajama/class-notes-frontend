// 1. Standard library
import SwiftUI

/// Root view that determines which view to show based on authentication status
struct RootView: View {
    // MARK: - Properties
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Environment(\.authenticationService) private var authService

    // MARK: - Body
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                ClassNotesSignInView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .task {
            await authViewModel.checkAuthenticationStatus()
        }
    }
}

// MARK: - Preview
#Preview {
    RootView()
        .environmentObject(AuthenticationViewModel(authService: MockAuthenticationService()))
}
