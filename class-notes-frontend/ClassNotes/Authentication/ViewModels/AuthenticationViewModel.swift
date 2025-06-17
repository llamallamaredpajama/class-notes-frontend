import Combine
// 1. Standard library
import Foundation
import SwiftUI

/// ViewModel for authentication-related views
@MainActor
final class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var showError = false

    // MARK: - Private Properties

    private let authService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService

        Task {
            await checkAuthenticationStatus()
        }
    }

    // MARK: - Public Methods

    /// Sign in using Google authentication
    func signInWithGoogle() {
        Task {
            await performSignIn(provider: .google)
        }
    }

    /// Sign in using Apple authentication
    func signInWithApple() {
        Task {
            await performSignIn(provider: .apple)
        }
    }

    /// Sign out the current user
    func signOut() {
        Task {
            await performSignOut()
        }
    }

    /// Check and update authentication status
    func checkAuthenticationStatus() async {
        isLoading = true
        defer { isLoading = false }

        isAuthenticated = await authService.checkAuthenticationStatus()
        if isAuthenticated {
            // Since both ViewModel and authService are @MainActor, we can access directly
            let user = await authService.currentUser
            self.currentUser = user
        }
    }

    /// Refresh authentication if needed
    func refreshAuthenticationIfNeeded() async {
        do {
            try await authService.refreshTokenIfNeeded()
        } catch {
            handleError(error)
        }
    }

    // MARK: - Private Methods

    private enum AuthProvider {
        case google
        case apple
    }

    private func performSignIn(provider: AuthProvider) async {
        isLoading = true
        errorMessage = nil
        showError = false

        defer { isLoading = false }

        do {
            switch provider {
            case .google:
                try await authService.signInWithGoogle()
            case .apple:
                try await authService.signInWithApple()
            }

            isAuthenticated = true
            // Since both ViewModel and authService are @MainActor, we can access directly
            let user = await authService.currentUser
            self.currentUser = user
        } catch {
            handleError(error)
        }
    }

    private func performSignOut() async {
        isLoading = true
        defer { isLoading = false }

        await authService.signOut()
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
    }

    private func handleError(_ error: Error) {
        if let appError = error as? AppError {
            errorMessage = appError.errorDescription
        } else {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        showError = true
    }
}

// MARK: - Environment Key

private struct AuthenticationViewModelKey: EnvironmentKey {
    static let defaultValue: AuthenticationViewModel? = nil
}

extension EnvironmentValues {
    var authenticationViewModel: AuthenticationViewModel? {
        get { self[AuthenticationViewModelKey.self] }
        set { self[AuthenticationViewModelKey.self] = newValue }
    }
}
