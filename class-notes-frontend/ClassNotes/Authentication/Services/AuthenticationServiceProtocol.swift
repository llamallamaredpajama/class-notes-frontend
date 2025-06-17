import Foundation
import SwiftData

/// Protocol defining the authentication service interface
@MainActor
protocol AuthenticationServiceProtocol {
    /// Indicates whether the user is currently authenticated
    var isAuthenticated: Bool { get async }

    /// The currently authenticated user, if any
    var currentUser: User? { get async }

    /// Sign in with the default authentication method
    func signIn() async throws

    /// Sign in using Google authentication
    func signInWithGoogle() async throws

    /// Sign in using Apple authentication
    func signInWithApple() async throws

    /// Sign out the current user
    func signOut() async

    /// Check if the user is currently authenticated
    func checkAuthenticationStatus() async -> Bool

    /// Refresh the authentication token if needed
    func refreshTokenIfNeeded() async throws
}
