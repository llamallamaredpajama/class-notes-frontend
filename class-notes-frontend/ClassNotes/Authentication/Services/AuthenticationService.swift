import Foundation
import SwiftData

/// Main authentication service implementation
final class AuthenticationService: AuthenticationServiceProtocol {
    private let googleService: GoogleSignInServiceProtocol
    private let keychainService: KeychainServiceProtocol
    private let modelContext: ModelContext?
    
    private var _currentUser: User?
    
    init(
        googleService: GoogleSignInServiceProtocol,
        keychainService: KeychainServiceProtocol = KeychainService.shared,
        modelContext: ModelContext? = nil
    ) {
        self.googleService = googleService
        self.keychainService = keychainService
        self.modelContext = modelContext
    }
    
    // MARK: - AuthenticationServiceProtocol
    
    var isAuthenticated: Bool {
        get async {
            await checkAuthenticationStatus()
        }
    }
    
    var currentUser: User? {
        get async {
            if _currentUser == nil {
                await loadCurrentUser()
            }
            return _currentUser
        }
    }
    
    func signIn() async throws {
        // Default to Google sign in for now
        try await signInWithGoogle()
    }
    
    func signInWithGoogle() async throws {
        do {
            let googleUser = try await googleService.signIn()
            
            // Create or update user
            let user = User(
                email: googleUser.email,
                displayName: googleUser.displayName,
                profileImageURL: googleUser.profileImageURL,
                authProvider: "google"
            )
            
            // Save auth token to keychain
            if let token = googleUser.idToken {
                _ = keychainService.saveString(token, for: KeychainService.Key.authToken)
            }
            
            // Save user ID to keychain
            _ = keychainService.saveString(user.id.uuidString, for: KeychainService.Key.userID)
            
            // Update user in database if context available
            if let modelContext = modelContext {
                modelContext.insert(user)
                try modelContext.save()
            }
            
            _currentUser = user
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }
    
    func signOut() async {
        // Sign out from Google
        await googleService.signOut()
        
        // Clear keychain
        _ = keychainService.delete(key: KeychainService.Key.authToken)
        _ = keychainService.delete(key: KeychainService.Key.refreshToken)
        _ = keychainService.delete(key: KeychainService.Key.userID)
        
        // Clear current user
        _currentUser = nil
    }
    
    func checkAuthenticationStatus() async -> Bool {
        // Check if we have a valid auth token
        guard let _ = keychainService.loadString(key: KeychainService.Key.authToken) else {
            return false
        }
        
        // Check if we have a user ID
        guard let userIDString = keychainService.loadString(key: KeychainService.Key.userID),
              let _ = UUID(uuidString: userIDString) else {
            return false
        }
        
        // TODO: Validate token with backend
        // For now, assume token is valid if it exists
        
        return true
    }
    
    func refreshTokenIfNeeded() async throws {
        // Check if token needs refresh
        guard let token = keychainService.loadString(key: KeychainService.Key.authToken) else {
            throw AuthenticationError.tokenExpired
        }
        
        // TODO: Implement token refresh logic
        // For now, just validate that we have a token
        
        if token.isEmpty {
            throw AuthenticationError.tokenExpired
        }
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentUser() async {
        guard let userIDString = keychainService.loadString(key: KeychainService.Key.userID),
              let userID = UUID(uuidString: userIDString),
              let modelContext = modelContext else {
            return
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.id == userID
            }
        )
        
        do {
            let users = try modelContext.fetch(descriptor)
            _currentUser = users.first
        } catch {
            print("Failed to load user: \(error)")
        }
    }
}

/// Mock authentication service for SwiftUI previews
final class MockAuthenticationService: AuthenticationServiceProtocol {
    var mockIsAuthenticated = false
    var mockUser: User?
    
    var isAuthenticated: Bool {
        get async { mockIsAuthenticated }
    }
    
    var currentUser: User? {
        get async { mockUser }
    }
    
    func signIn() async throws {
        mockIsAuthenticated = true
        mockUser = User(
            email: "test@example.com",
            displayName: "Test User",
            authProvider: "mock"
        )
    }
    
    func signInWithGoogle() async throws {
        try await signIn()
    }
    
    func signOut() async {
        mockIsAuthenticated = false
        mockUser = nil
    }
    
    func checkAuthenticationStatus() async -> Bool {
        mockIsAuthenticated
    }
    
    func refreshTokenIfNeeded() async throws {
        // No-op for mock
    }
} 