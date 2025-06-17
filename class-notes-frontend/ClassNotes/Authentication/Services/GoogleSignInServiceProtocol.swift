import Foundation

/// Protocol defining the Google Sign-In service interface
@MainActor
protocol GoogleSignInServiceProtocol {
    /// Indicates whether sign-in is currently in progress
    var isSigningIn: Bool { get }

    /// The last error that occurred during sign-in, if any
    var error: Error? { get }

    /// Initiate Google Sign-In flow
    func signIn() async throws -> GoogleUser

    /// Sign out the current Google user
    func signOut() async

    /// Restore previous sign-in session if available
    func restorePreviousSignIn() async -> GoogleUser?

    /// Handle URL for OAuth callback
    nonisolated func handle(_ url: URL) -> Bool
}

/// Represents a Google user after successful authentication
struct GoogleUser: Sendable {
    let id: String
    let email: String
    let displayName: String
    let profileImageURL: URL?
    let idToken: String?
    let accessToken: String?
}
