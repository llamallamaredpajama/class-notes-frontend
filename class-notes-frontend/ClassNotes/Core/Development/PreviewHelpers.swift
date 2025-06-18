#if DEBUG
import SwiftUI
import GoogleSignIn
import SwiftData

// MARK: - View Extensions for Previews
extension View {
    /// Wraps the view as a component with padding and background
    func previewAsComponent() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .previewLayout(.sizeThatFits)
    }
    
    /// Sets up device preview with display name
    func previewWithDevice(_ device: PreviewDevice) -> some View {
        self
            .previewDevice(device)
            .previewDisplayName(device.rawValue)
    }
    
    /// Quick preview for different color schemes
    func previewColorSchemes() -> some View {
        ForEach(ColorScheme.allCases, id: \.self) { scheme in
            self
                .preferredColorScheme(scheme)
                .previewDisplayName(scheme == .light ? "Light Mode" : "Dark Mode")
        }
    }
}

// MARK: - Mock Data for Previews
struct MockData {
    // MARK: - Preview Data Structures
    
    /// Preview-safe lesson structure
    struct PreviewLesson: Identifiable {
        let id = UUID()
        let title: String
        let date: Date
        let duration: Int
        let transcript: String
        let isFavorite: Bool
        let tags: [String]
        let syncStatus: SyncStatus
        
        var formattedDuration: String {
            let hours = duration / 3600
            let minutes = (duration % 3600) / 60
            
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else if minutes > 0 {
                return "\(minutes)m"
            } else {
                return "\(duration)s"
            }
        }
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        var transcriptSummary: String {
            let maxLength = 200
            if transcript.count > maxLength {
                return String(transcript.prefix(maxLength)) + "..."
            }
            return transcript
        }
    }
    
    /// Preview-safe user structure
    struct PreviewUser {
        let id = UUID()
        let email: String
        let displayName: String
        let authProvider: String
        let profileImageURL: URL?
        
        init(email: String, displayName: String, authProvider: String, profileImageURL: URL? = nil) {
            self.email = email
            self.displayName = displayName
            self.authProvider = authProvider
            self.profileImageURL = profileImageURL
        }
    }
    
    // Sample Lesson data for actual Lesson objects
    static let sampleLesson: Lesson = {
        let lesson = Lesson(
            title: "Introduction to SwiftUI",
            date: Date(),
            duration: 3600,
            transcript: "Welcome to SwiftUI fundamentals. Today we'll explore the declarative syntax and learn how to build beautiful user interfaces.",
            tags: ["SwiftUI", "iOS", "Development"],
            isFavorite: false
        )
        return lesson
    }()
    
    // Sample Lesson data for previews (PreviewLesson type)
    static let samplePreviewLesson = PreviewLesson(
        title: "Introduction to SwiftUI",
        date: Date(),
        duration: 3600,
        transcript: "Welcome to SwiftUI fundamentals. Today we'll explore the declarative syntax and learn how to build beautiful user interfaces.",
        isFavorite: false,
        tags: ["SwiftUI", "iOS", "Development"],
        syncStatus: .synced
    )
    
    static let sampleLessons = [
        PreviewLesson(
            title: "Introduction to SwiftUI",
            date: Date(),
            duration: 3600,
            transcript: "Welcome to SwiftUI fundamentals...",
            isFavorite: true,
            tags: ["SwiftUI", "iOS"],
            syncStatus: SyncStatus.synced
        ),
        PreviewLesson(
            title: "Advanced SwiftUI Patterns",
            date: Date().addingTimeInterval(-86400),
            duration: 5400,
            transcript: "Building on our SwiftUI knowledge...",
            isFavorite: false,
            tags: ["SwiftUI", "Advanced"],
            syncStatus: SyncStatus.synced
        ),
        PreviewLesson(
            title: "Core Data Integration",
            date: Date().addingTimeInterval(-172800),
            duration: 4200,
            transcript: "Persisting data with Core Data...",
            isFavorite: true,
            tags: ["Core Data", "iOS"],
            syncStatus: SyncStatus.notSynced
        )
    ]
    
    // Sample User data for actual User objects
    static let sampleUser: User = {
        let user = User(
            email: "preview@classnotes.app",
            displayName: "Preview User",
            authProvider: "google"
        )
        return user
    }()
    
    // Sample User data for previews (PreviewUser type)
    static let samplePreviewUser = PreviewUser(
        email: "preview@classnotes.app",
        displayName: "Preview User",
        authProvider: "google"
    )
    
    // Sample error for testing error states
    static let sampleError = NSError(
        domain: "com.classnotes.preview",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Sample error for preview"]
    )
}

// MARK: - Preview Environment Configuration
struct PreviewEnvironment {
    static func configure() -> some View {
        EmptyView()
            .onAppear {
                // Configure any preview-specific settings here
                UserDefaults.standard.set(true, forKey: "preview_mode")
            }
    }
    
    /// Creates a preview model container with sample data
    static func modelContainer() -> ModelContainer {
        let schema = Schema([
            Lesson.self,
            User.self,
            Course.self,
            Note.self,
            AudioRecording.self,
            DrawingCanvas.self,
            UserPreferences.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

// MARK: - Common Preview Layouts
struct PreviewLayouts {
    static let devices: [PreviewDevice] = [
        PreviewDevice(rawValue: "iPhone 15 Pro"),
        PreviewDevice(rawValue: "iPhone 15 Pro Max"),
        PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"),
        PreviewDevice(rawValue: "iPad mini (6th generation)")
    ]
}

// MARK: - Preview Modifiers
extension View {
    /// Adds a SwiftData model container for previews
    func previewModelContainer() -> some View {
        self.modelContainer(PreviewEnvironment.modelContainer())
    }
}
#endif 
