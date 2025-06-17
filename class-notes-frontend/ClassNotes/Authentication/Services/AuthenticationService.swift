import Foundation
import SwiftData

/// Main authentication service implementation
@MainActor
final class AuthenticationService: AuthenticationServiceProtocol {
    // MARK: - Singleton
    static let shared = AuthenticationService(
        googleService: GoogleSignInService(),
        appleService: AppleSignInService()
    )
    
    private let googleService: GoogleSignInServiceProtocol
    private let appleService: AppleSignInServiceProtocol
    private let keychainService: KeychainServiceProtocol
    private let modelContext: ModelContext?

    private var _currentUser: User?

    init(
        googleService: GoogleSignInServiceProtocol,
        appleService: AppleSignInServiceProtocol,
        keychainService: KeychainServiceProtocol = KeychainService.shared,
        modelContext: ModelContext? = nil
    ) {
        self.googleService = googleService
        self.appleService = appleService
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
                // Since we're @MainActor, we can work with modelContext directly
                modelContext.insert(user)
                try? modelContext.save()
            }

            _currentUser = user
        } catch {
            throw AppError(error)
        }
    }

    func signInWithApple() async throws {
        do {
            let appleUser = try await appleService.signIn()

            // Create or update user
            let user = User(
                email: appleUser.email ?? "",
                displayName: appleUser.displayName,
                profileImageURL: nil,
                authProvider: "apple"
            )

            // Save auth token to keychain
            if let token = appleUser.identityToken {
                _ = keychainService.saveString(token, for: KeychainService.Key.authToken)
            }

            // Save user ID to keychain
            _ = keychainService.saveString(user.id.uuidString, for: KeychainService.Key.userID)

            // Update user in database if context available
            if let modelContext = modelContext {
                // Since we're @MainActor, we can work with modelContext directly
                modelContext.insert(user)
                try? modelContext.save()
            }

            _currentUser = user
        } catch {
            throw AppError(error)
        }
    }

    func signOut() async {
        // Sign out from Google
        await googleService.signOut()

        // Sign out from Apple
        await appleService.signOut()

        // Clear keychain
        _ = keychainService.delete(key: KeychainService.Key.authToken)
        _ = keychainService.delete(key: KeychainService.Key.refreshToken)
        _ = keychainService.delete(key: KeychainService.Key.userID)

        // Clear Apple Sign In specific data
        keychainService.clearAppleUserData()

        // Clear current user
        _currentUser = nil
    }

    func checkAuthenticationStatus() async -> Bool {
        // Check if we have a valid auth token
        guard keychainService.loadString(key: KeychainService.Key.authToken) != nil else {
            return false
        }

        // Check if we have a user ID
        guard let userIDString = keychainService.loadString(key: KeychainService.Key.userID),
            UUID(uuidString: userIDString) != nil
        else {
            return false
        }

        // TODO: Validate token with backend
        // For now, assume token is valid if it exists

        return true
    }

    func refreshTokenIfNeeded() async throws {
        // Check if token needs refresh
        guard let token = keychainService.loadString(key: KeychainService.Key.authToken) else {
            throw AppError.authentication("Authentication token has expired")
        }

        // TODO: Implement token refresh logic
        // For now, just validate that we have a token

        if token.isEmpty {
            throw AppError.authentication("Authentication token has expired")
        }
    }

    // MARK: - Private Methods

    private func loadCurrentUser() async {
        guard let userIDString = keychainService.loadString(key: KeychainService.Key.userID),
            let userID = UUID(uuidString: userIDString),
            let modelContext = modelContext
        else {
            return
        }

        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.id == userID
            }
        )

        do {
            // Since we're @MainActor, we can fetch directly without actor switching
            let users = try modelContext.fetch(descriptor)
            if let user = users.first {
                _currentUser = user
            }
        } catch {
            print("Failed to load user: \(error)")
        }
    }
}

/// Mock authentication service for SwiftUI previews and simulator testing
@MainActor
final class MockAuthenticationService: AuthenticationServiceProtocol {
    private var mockIsAuthenticated = false
    private var mockUser: User?

    /// Simulated delay for authentication operations (in seconds)
    private let simulatedDelay: TimeInterval = 0.5

    var isAuthenticated: Bool {
        get async { mockIsAuthenticated }
    }

    var currentUser: User? {
        get async { mockUser }
    }

    func signIn() async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))

        // Create a mock user with realistic data
        mockIsAuthenticated = true
        mockUser = User(
            email: "test.user@classnotes.dev",
            displayName: "Test User",
            profileImageURL: URL(string: "https://ui-avatars.com/api/?name=Test+User&size=200"),
            authProvider: "mock"
        )

        // Simulate creating default preferences
        mockUser?.preferences = UserPreferences()

        print("✅ Mock Authentication: User signed in successfully")
    }

    func signInWithGoogle() async throws {
        print("🔵 Mock Authentication: Simulating Google Sign-In...")
        try await signIn()
    }

    func signInWithApple() async throws {
        print("🍎 Mock Authentication: Simulating Apple Sign-In...")

        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))

        // Create a mock user with Apple-specific data
        mockIsAuthenticated = true
        mockUser = User(
            email: "test.user@icloud.com",
            displayName: "Apple Test User",
            profileImageURL: URL(string: "https://ui-avatars.com/api/?name=Apple+User&size=200"),
            authProvider: "apple"
        )

        // Simulate creating default preferences
        mockUser?.preferences = UserPreferences()

        print("✅ Mock Authentication: Apple user signed in successfully")
    }

    func signOut() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: UInt64(0.2 * 1_000_000_000))

        mockIsAuthenticated = false
        mockUser = nil

        print("👋 Mock Authentication: User signed out")
    }

    func checkAuthenticationStatus() async -> Bool {
        // Simulate checking auth status
        try? await Task.sleep(nanoseconds: UInt64(0.1 * 1_000_000_000))

        print(
            "🔍 Mock Authentication: Checking auth status - \(mockIsAuthenticated ? "Authenticated" : "Not authenticated")"
        )
        return mockIsAuthenticated
    }

    func refreshTokenIfNeeded() async throws {
        // Simulate token refresh
        try await Task.sleep(nanoseconds: UInt64(0.3 * 1_000_000_000))
        print("🔄 Mock Authentication: Token refreshed (simulated)")
    }
}
