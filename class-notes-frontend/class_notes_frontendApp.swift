//
//  class_notes_frontendApp.swift
//  class-notes-frontend
//
//  Created by Jeremy M. Hoenig, MD on 6/6/25.
//

import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct class_notes_frontendApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Configure Google Sign-In on app launch
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["GIDClientID"] as? String else {
            fatalError("Google Sign-In configuration not found. Please add GIDClientID to Info.plist")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        
        // Restore previous sign-in if available
        GoogleSignInService.shared.restorePreviousSignIn()
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                ClassNotesSignInView()
                    .environmentObject(authManager)
            }
        }
        .modelContainer(sharedModelContainer)
        .onOpenURL { url in
            // Handle Google Sign-In callback
            GoogleSignInService.shared.handle(url)
        }
    }
}
