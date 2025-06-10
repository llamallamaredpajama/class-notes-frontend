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
    // Sample Lesson data
    static let sampleLesson = Lesson(
        title: "Introduction to SwiftUI",
        date: Date(),
        duration: 3600,
        transcript: "Welcome to SwiftUI fundamentals. Today we'll explore the declarative syntax and learn how to build beautiful user interfaces."
    )
    
    static let sampleLessons = [
        Lesson(
            title: "Introduction to SwiftUI",
            date: Date(),
            duration: 3600,
            transcript: "Welcome to SwiftUI fundamentals..."
        ),
        Lesson(
            title: "Advanced SwiftUI Patterns",
            date: Date().addingTimeInterval(-86400),
            duration: 5400,
            transcript: "Building on our SwiftUI knowledge..."
        ),
        Lesson(
            title: "Core Data Integration",
            date: Date().addingTimeInterval(-172800),
            duration: 4200,
            transcript: "Persisting data with Core Data..."
        )
    ]
    
    // Sample User data
    static let sampleUser = User(
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
#endif 
