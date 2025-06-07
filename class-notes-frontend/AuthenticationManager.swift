import SwiftUI
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private init() {
        // Check for stored authentication token or credentials
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        // Check UserDefaults or Keychain for stored auth token
        // For now, we'll just check a simple UserDefaults flag
        isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
    }
    
    func signIn() {
        // Update authentication state
        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        
        // In a real app, you would:
        // 1. Store auth tokens securely in Keychain
        // 2. Update user information
        // 3. Sync with backend
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        
        // Clear any stored tokens or credentials
    }
}

// Simple User model
struct User {
    let id: String
    let email: String
    let fullName: String?
} 