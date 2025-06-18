import SwiftData
import Foundation
import SwiftUI

/// Controller for managing SwiftData persistence
final class PersistenceController {
    static let shared = PersistenceController()
    
    /// The main model container
    let container: ModelContainer
    
    /// Model context for main thread operations
    @MainActor
    var viewContext: ModelContext {
        container.mainContext
    }
    
    private init() {
        do {
            // Configure model container with app group for sharing
            let appGroupID = "group.com.classnotes.app"
            let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            let modelURL = appGroupURL?.appendingPathComponent("ClassNotes.sqlite")
            
            let schema = Schema([
                User.self,
                UserPreferences.self,
                Lesson.self,
                Note.self,
                Course.self,
                AudioRecording.self,
                DrawingCanvas.self
            ])
            
            let modelConfiguration: ModelConfiguration
            if let modelURL = modelURL {
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    url: modelURL,
                    allowsSave: true,
                    cloudKitDatabase: .automatic
                )
            } else {
                modelConfiguration = ModelConfiguration(
                    schema: schema,
                    allowsSave: true,
                    cloudKitDatabase: .automatic
                )
            }
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }
    
    /// Create a background context for heavy operations
    func newBackgroundContext() -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }
    
    /// Perform a background task with a dedicated context
    func performBackgroundTask<T>(_ block: @escaping (ModelContext) throws -> T) async throws -> T {
        let context = newBackgroundContext()
        return try await Task.detached {
            try block(context)
        }.value
    }
    
    /// Save changes in a context
    func save(context: ModelContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    #if DEBUG
    /// Preview container for SwiftUI previews
    static let preview: PersistenceController = {
        let controller = PersistenceController.inMemory()
        
        // Add sample data
        Task { @MainActor in
            let context = controller.viewContext
            
            // Sample user
            let user = User(
                email: "preview@example.com",
                displayName: "Preview User",
                authProvider: "preview"
            )
            context.insert(user)
            
            // Sample course
            let course = Course(
                name: "Mathematics 101",
                instructor: "Dr. Smith",
                color: .red
            )
            context.insert(course)
            
            // Sample lessons
            for i in 1...5 {
                let lesson = Lesson(
                    title: "Lesson \(i)"
                )
                lesson.course = course
                lesson.orderIndex = i
                context.insert(lesson)
            }
            
            try? context.save()
        }
        
        return controller
    }()
    
    /// Create an in-memory container for testing
    private init(inMemory: Bool) {
        do {
            let schema = Schema([
                User.self,
                UserPreferences.self,
                Lesson.self,
                Note.self,
                Course.self,
                AudioRecording.self,
                DrawingCanvas.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create in-memory container: \(error)")
        }
    }
    
    /// Create an in-memory container for testing
    static func inMemory() -> PersistenceController {
        return PersistenceController(inMemory: true)
    }
    #endif
}

// MARK: - Environment Values

private struct PersistenceControllerKey: EnvironmentKey {
    static let defaultValue = PersistenceController.shared
}

extension EnvironmentValues {
    var persistenceController: PersistenceController {
        get { self[PersistenceControllerKey.self] }
        set { self[PersistenceControllerKey.self] = newValue }
    }
}