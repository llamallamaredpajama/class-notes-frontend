//
//  class_notes_frontendApp.swift
//  class-notes-frontend
//
//  Created by Jeremy M. Hoenig, MD on 6/6/25.
//

import SwiftUI
import SwiftData

@main
struct class_notes_frontendApp: App {
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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
