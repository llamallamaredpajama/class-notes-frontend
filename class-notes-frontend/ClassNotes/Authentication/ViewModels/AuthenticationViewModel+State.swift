// 1. Standard library
import Foundation

// MARK: - Authentication State

/// Equatable state representation for AuthenticationViewModel
/// This enables SwiftUI to efficiently determine when views need to be redrawn
struct AuthenticationState: Equatable {
    var isAuthenticated: Bool = false
    var currentUser: UserInfo? = nil
    var isLoading: Bool = false
    var error: AuthError? = nil
    
    /// Lightweight user representation for state comparison
    struct UserInfo: Equatable {
        let id: UUID
        let email: String
        let displayName: String
        let profileImageURL: URL?
        let authProvider: String
        
        init(from user: User) {
            self.id = user.id
            self.email = user.email
            self.displayName = user.displayName
            self.profileImageURL = user.profileImageURL
            self.authProvider = user.authProvider
        }
    }
    
    /// Equatable error representation
    struct AuthError: Equatable {
        let message: String
        let code: String
        
        init(message: String, code: String = "unknown") {
            self.message = message
            self.code = code
        }
        
        init(from error: Error) {
            if let appError = error as? AppError {
                self.message = appError.errorDescription ?? "Unknown error"
                self.code = appError.errorCode
            } else {
                self.message = error.localizedDescription
                self.code = "system"
            }
        }
    }
}

// MARK: - AppError Extension

extension AppError {
    /// Error code for equatable comparison
    var errorCode: String {
        switch self {
        case .authentication:
            return "auth"
        case .network:
            return "network"
        case .storage:
            return "storage"
        case .processing:
            return "processing"
        case .audio:
            return "audio"
        case .lesson:
            return "lesson"
        }
    }
}

// MARK: - ViewModel Extension

extension AuthenticationViewModel {
    /// Current state for efficient SwiftUI updates
    var state: AuthenticationState {
        AuthenticationState(
            isAuthenticated: isAuthenticated,
            currentUser: currentUser.map { AuthenticationState.UserInfo(from: $0) },
            isLoading: isLoading,
            error: errorMessage.map { AuthenticationState.AuthError(message: $0) }
        )
    }
    
    /// Compare states to determine if view update is needed
    func stateDidChange(from oldState: AuthenticationState, to newState: AuthenticationState) -> Bool {
        return oldState != newState
    }
} 