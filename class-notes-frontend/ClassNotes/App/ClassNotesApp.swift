import SwiftUI
import SwiftData
import GoogleSignIn

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
        let keychainService = KeychainService.shared
        let googleService = GoogleSignInService(keychainService: keychainService)
        return AuthenticationService(
            googleService: googleService,
            keychainService: keychainService,
            modelContext: PersistenceController.shared.container.mainContext
        )
    }
    
    // MARK: - Initialization
    
    init() {
        let service = Self.makeAuthService()
        self.authService = service
        self._authViewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: service))
        
        // Configure Google Sign-In
        // Self.configureGoogleSignIn() // TODO: Uncomment when GoogleService-Info.plist is added
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.authenticationService, authService)
                .environment(\.persistenceController, persistenceController)
                .environmentObject(authViewModel)
                .modelContainer(persistenceController.container)
                // TODO: Uncomment when GoogleService-Info.plist is added
                /*
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                */
        }
    }
    
    // MARK: - Private Methods
    
    private static func configureGoogleSignIn() {
        // TODO: Add GoogleService-Info.plist to the project before uncommenting
        /*
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("GoogleService-Info.plist not found or CLIENT_ID missing")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        */
        
        // Temporary configuration for development
        print("Warning: Google Sign-In not configured. Add GoogleService-Info.plist to enable.")
    }
}

/// Root view that determines which view to show based on authentication status
struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Environment(\.authenticationService) private var authService
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                ClassNotesSignInView(authService: authService)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .task {
            await authViewModel.checkAuthenticationStatus()
        }
    }
}

/// Main tab view for authenticated users
struct MainTabView: View {
    var body: some View {
        TabView {
            LessonsListView()
                .tabItem {
                    Label("Lessons", systemImage: "book.fill")
                }
            
            CoursesListView()
                .tabItem {
                    Label("Courses", systemImage: "folder.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

// MARK: - Environment Keys

private struct AuthenticationServiceKey: EnvironmentKey {
    static let defaultValue: AuthenticationServiceProtocol = MockAuthenticationService()
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
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Additional app configuration
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // TODO: Uncomment when GoogleService-Info.plist is added
        // return GIDSignIn.sharedInstance.handle(url)
        return false
    }
}
#endif

 