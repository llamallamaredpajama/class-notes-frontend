import Foundation

/// Protocol defining the authentication service interface
protocol AuthenticationServiceProtocol {
    /// Indicates whether the user is currently authenticated
    var isAuthenticated: Bool { get async }
    
    /// The currently authenticated user, if any
    var currentUser: User? { get async }
    
    /// Sign in the user using the default authentication method
    func signIn() async throws
    
    /// Sign in using Google authentication
    func signInWithGoogle() async throws
    
    /// Sign out the current user
    func signOut() async
    
    /// Check if the user has a valid authentication session
    func checkAuthenticationStatus() async -> Bool
    
    /// Refresh the authentication token if needed
    func refreshTokenIfNeeded() async throws
}

/// Error types for authentication operations
enum AuthenticationError: LocalizedError {
    case invalidCredentials
    case networkError
    case tokenExpired
    case userCancelled
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .userCancelled:
            return "Sign in was cancelled."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
} 