import SwiftUI
import GoogleSignIn
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
class GoogleSignInService: NSObject, ObservableObject {
    static let shared = GoogleSignInService()
    
    @Published var isSigningIn = false
    @Published var error: Error?
    
    private override init() {
        super.init()
    }
    
    func signIn() {
        #if os(iOS)
        guard let presentingViewController = getRootViewController() else {
            print("Error: No presenting view controller available")
            return
        }
        
        isSigningIn = true
        error = nil
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            self?.handleSignInResult(result: result, error: error)
        }
        #elseif os(macOS)
        guard let presentingWindow = NSApplication.shared.keyWindow else {
            print("Error: No presenting window available")
            return
        }
        
        isSigningIn = true
        error = nil
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) { [weak self] result, error in
            self?.handleSignInResult(result: result, error: error)
        }
        #endif
    }
    
    private func handleSignInResult(result: GIDSignInResult?, error: Error?) {
        isSigningIn = false
        
        if let error = error {
            self.error = error
            print("Google Sign-In error: \(error.localizedDescription)")
            return
        }
        
        guard let result = result else {
            print("Google Sign-In: No result")
            return
        }
        
        // Successfully signed in
        let user = result.user
        print("Google Sign-In successful for user: \(user.profile?.email ?? "No email")")
        
        // Get ID token for backend authentication if needed
        if let idToken = user.idToken?.tokenString {
            print("ID Token available for backend authentication")
            // Send this token to your backend for verification
        }
        
        // Update authentication state
        AuthenticationManager.shared.signIn()
        
        // Store user info if needed
        storeUserInfo(user)
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        AuthenticationManager.shared.signOut()
    }
    
    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let error = error {
                print("Restore sign-in error: \(error.localizedDescription)")
                return
            }
            
            if let user = user {
                print("Previous sign-in restored for: \(user.profile?.email ?? "No email")")
                AuthenticationManager.shared.signIn()
                self?.storeUserInfo(user)
            }
        }
    }
    
    private func storeUserInfo(_ user: GIDGoogleUser) {
        // Store user information as needed
        if let profile = user.profile {
            let userInfo = User(
                id: user.userID ?? UUID().uuidString,
                email: profile.email,
                fullName: profile.name
            )
            AuthenticationManager.shared.currentUser = userInfo
        }
    }
    
    #if os(iOS)
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    #endif
}

// MARK: - URL Handling
extension GoogleSignInService {
    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
} 