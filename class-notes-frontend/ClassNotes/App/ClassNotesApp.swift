// 2. Apple frameworks
import AuthenticationServices
// 1. Standard library
import Foundation
// 3. Third-party dependencies
import GoogleSignIn
import SwiftData
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

/// Main entry point for the Class Notes app
@main
struct ClassNotesApp: App {
    // MARK: - Properties

    #if canImport(UIKit)
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    private let persistenceController = PersistenceController.shared
    private let keychainService = KeychainService.shared
    private let authService: AuthenticationServiceProtocol

    @StateObject private var authViewModel: AuthenticationViewModel

    // MARK: - Initialization Helper

    private static func makeAuthService() -> AuthenticationServiceProtocol {
        #if targetEnvironment(simulator)
            // Use mock service for simulator
            print("📱 Running on Simulator - Using Mock Authentication Service")
            return MockAuthenticationService()
        #else
            // Use real service for physical device
            print("📱 Running on Physical Device - Using Real Authentication Service")
            let keychainService = KeychainService.shared
            let googleService = GoogleSignInService(keychainService: keychainService)
            let appleService = AppleSignInService(keychainService: keychainService)
            return AuthenticationService(
                googleService: googleService,
                appleService: appleService,
                keychainService: keychainService,
                modelContext: PersistenceController.shared.container.mainContext
            )
        #endif
    }

    // MARK: - Initialization

    init() {
        let service = Self.makeAuthService()
        self.authService = service
        self._authViewModel = StateObject(
            wrappedValue: AuthenticationViewModel(authService: service))

        // Configure Google Sign-In
        Self.configureGoogleSignIn()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.authenticationService, authService)
                .environment(\.persistenceController, persistenceController)
                .environmentObject(authViewModel)
                .modelContainer(persistenceController.container)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }

    // MARK: - Private Methods

    private static func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: path),
            let clientId = plist["CLIENT_ID"] as? String
        else {
            fatalError("GoogleService-Info.plist not found or CLIENT_ID missing")
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
}

// MARK: - Environment Keys

private struct AuthenticationServiceKey: EnvironmentKey {
    @MainActor
    static var defaultValue: AuthenticationServiceProtocol {
        MockAuthenticationService()
    }
}

extension EnvironmentValues {
    var authenticationService: AuthenticationServiceProtocol {
        get { self[AuthenticationServiceKey.self] }
        set { self[AuthenticationServiceKey.self] = newValue }
    }
}

// MARK: - App Delegate

#if canImport(UIKit)
    class AppDelegate: NSObject, UIApplicationDelegate {
        func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? =
                nil
        ) -> Bool {
            // Additional app configuration
            return true
        }

        func application(
            _ app: UIApplication,
            open url: URL,
            options: [UIApplication.OpenURLOptionsKey: Any] = [:]
        ) -> Bool {
            return GIDSignIn.sharedInstance.handle(url)
        }
    }
#endif
