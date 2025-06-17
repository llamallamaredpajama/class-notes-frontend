import AuthenticationServices
import Foundation

/// Protocol defining the Apple Sign-In service interface
@MainActor
protocol AppleSignInServiceProtocol {
    /// Indicates whether sign-in is currently in progress
    var isSigningIn: Bool { get }

    /// The last error that occurred during sign-in, if any
    var error: Error? { get }

    /// Initiate Apple Sign-In flow
    func signIn() async throws -> AppleUser

    /// Sign out the current Apple user
    func signOut() async

    /// Handle authorization data
    func handleAuthorization(
        userID: String,
        email: String?,
        fullName: Foundation.PersonNameComponents?,
        identityToken: Data?
    ) async throws -> AppleUser
}

/// Represents an Apple user after successful authentication
struct AppleUser: Sendable {
    let id: String
    let email: String?
    let fullName: Foundation.PersonNameComponents?
    let identityToken: String?

    var displayName: String {
        if let fullName = fullName {
            let formatter = PersonNameComponentsFormatter()
            return formatter.string(from: fullName)
        }
        return email ?? "Apple User"
    }
}
