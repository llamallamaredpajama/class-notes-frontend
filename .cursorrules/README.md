# Class Notes Frontend - SwiftUI iOS/iPadOS Application

# Rule Version: 1.0.0
# Last Updated: 2025-01-28
# Swift Version: 5.9+
# Platform: iOS 17+, iPadOS 17+, macOS 14+

## Quick Navigation
- 🎨 [UI/UX Patterns](./domains/ui.md)
- 📱 [SwiftUI Best Practices](./patterns/swiftui.md)
- 🔄 [State Management](./domains/state.md)
- 🌐 [Networking & gRPC](./domains/networking.md)
- 💾 [Data Persistence](./domains/data.md)
- 🔐 [Authentication](./patterns/authentication.md)
- 🧪 [Testing Strategies](./patterns/testing.md)
- 🔧 [Backend Integration](./integrations/backend.md)
- 🎙️ [Audio Processing](./implementations/audio.md)
- ✏️ [Drawing & PencilKit](./implementations/drawing.md)
- 📄 [Document Management](./implementations/documents.md)
- ⚡ [Quick Reference](./references/quick-ref.md)
- 📝 [Commands](./references/commands.md)
- 🔧 [Troubleshooting](./references/troubleshooting.md)
- ⚠️ [gRPC-Swift v2 Migration](./migrations/grpc-swift-v2.md)

---

## About This Project

You are an expert iOS/iPadOS developer specializing in SwiftUI, with deep expertise in:

- SwiftUI with iOS 17+ features (Observable, SwiftData where applicable)
- MVVM architecture with @MainActor for thread safety
- Async/await and structured concurrency
- gRPC-Swift for backend communication
- Core Data for offline storage
- WhisperKit for on-device audio transcription
- PencilKit for handwritten notes
- Firebase Authentication with Google Sign-In
- File Provider Extension for document management
- Modern iOS design patterns and best practices

## Project Overview

AI-powered educational iOS/iPadOS application that records class sessions, processes documents, and generates summarized PDFs. Features offline-first architecture with seamless cloud sync.

**Architecture**: MVVM with dependency injection and protocol-oriented design
**Language**: Swift 5.9+ with strict concurrency checking
**Platforms**: iOS 17+, iPadOS 17+, macOS 14+ (Designed for iPad)
**Key Features**: Audio transcription, document scanning, handwritten notes, AI summaries

## Repository Structure

```
class-notes-frontend/
├── class-notes-frontend/
│   ├── Assets.xcassets/          # App assets and icons
│   ├── ClassNotes/               # Main application code
│   │   ├── App/                  # App lifecycle and configuration
│   │   ├── Authentication/       # Auth flows and services
│   │   ├── Core/                 # Shared utilities and protocols
│   │   └── Lessons/              # Main feature module
│   ├── Scripts/                  # Build and automation scripts
│   └── WhisperKitModels/         # ML models for transcription
├── class-notes-frontendTests/    # Unit tests
└── class-notes-frontendUITests/  # UI tests
```

## Swift Standards

### Import Ordering (MANDATORY)

```swift
// 1. Standard library
import Foundation
import SwiftUI
import Combine

// 2. Apple frameworks
import CoreData
import PencilKit
import PhotosUI

// 3. Third-party dependencies
import Firebase
import GoogleSignIn
import GRPC
import WhisperKit

// 4. Local modules
import ClassNotesCore
import ClassNotesUI
```

### Naming Conventions

- **Files**: PascalCase matching type name (`LessonDetailView.swift`)
- **Types**: PascalCase (`LessonViewModel`, `DocumentProcessor`)
- **Protocols**: Descriptive names, often with -able suffix (`Persistable`, `AudioRecordable`)
- **Properties**: camelCase (`isProcessing`, `currentLesson`)
- **Methods**: camelCase verb phrases (`fetchDocuments()`, `startRecording()`)
- **Constants**: camelCase for instance, PascalCase for static (`defaultTimeout`, `static let MaxRetryCount`)

### SwiftUI View Structure

```swift
struct LessonDetailView: View {
    // MARK: - Properties
    @StateObject private var viewModel: LessonDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingError = false
    
    // MARK: - Body
    var body: some View {
        content
            .navigationTitle("Lesson Details")
            .toolbar { toolbarContent }
            .task { await viewModel.loadData() }
            .alert("Error", isPresented: $isShowingError) { errorAlert }
    }
    
    // MARK: - Views
    @ViewBuilder
    private var content: some View {
        // Main content
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Toolbar items
    }
}

// MARK: - Preview
#Preview {
    LessonDetailView(viewModel: .preview)
}
```

### MVVM Pattern

```swift
@MainActor
final class LessonViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var lessons: [Lesson] = []
    @Published private(set) var isLoading = false
    @Published var error: AppError?
    
    // MARK: - Dependencies
    private let lessonService: LessonServiceProtocol
    private let audioService: AudioServiceProtocol
    
    // MARK: - Initialization
    init(
        lessonService: LessonServiceProtocol = LessonService.shared,
        audioService: AudioServiceProtocol = AudioService.shared
    ) {
        self.lessonService = lessonService
        self.audioService = audioService
    }
    
    // MARK: - Methods
    func loadLessons() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            lessons = try await lessonService.fetchLessons()
        } catch {
            self.error = AppError(error)
        }
    }
}
```

## Current Implementation Status

### ✅ Implemented
- Google Sign-In with Firebase Authentication
- Core Data models for offline storage
- Basic lesson creation and management
- Audio recording with AVAudioEngine
- Document scanning with VisionKit
- PencilKit integration for drawings
- gRPC client setup with interceptors
- Basic error handling and alerts
- Settings and user preferences

### 🚧 In Progress / Planned
- WhisperKit integration for transcription
- Real-time sync with backend
- File Provider Extension
- iPad-optimized layouts
- Advanced search and filtering
- Batch operations UI
- Export functionality
- Sharing extensions
- Widget support
- App Clips for quick access

## Common Pitfalls to AVOID

❌ Force unwrapping optionals
❌ Synchronous network calls on main thread
❌ Ignoring @MainActor requirements
❌ Direct Core Data access from views
❌ Missing error handling in async functions
❌ Retaining self in closures without weak/unowned
❌ Using UserDefaults for sensitive data
❌ Hardcoding API endpoints
❌ Creating unnecessary view refreshes
❌ Ignoring iPad multitasking

## Implementation Checklist

When implementing new features:

- [ ] Define protocols for testability
- [ ] Implement offline support first
- [ ] Add proper error handling
- [ ] Use dependency injection
- [ ] Write unit tests
- [ ] Test on both iPhone and iPad
- [ ] Check memory usage and leaks
- [ ] Implement proper loading states
- [ ] Add accessibility support
- [ ] Document complex logic
- [ ] Consider landscape orientation
- [ ] Test with poor network conditions

## Architecture Patterns

### Dependency Injection

```swift
protocol LessonServiceProtocol {
    func fetchLessons() async throws -> [Lesson]
    func createLesson(_ lesson: Lesson) async throws
}

final class LessonService: LessonServiceProtocol {
    static let shared = LessonService()
    
    private let grpcClient: ClassNotesServiceAsyncClient
    private let coreDataManager: CoreDataManager
    
    init(
        grpcClient: ClassNotesServiceAsyncClient = .shared,
        coreDataManager: CoreDataManager = .shared
    ) {
        self.grpcClient = grpcClient
        self.coreDataManager = coreDataManager
    }
}
```

### Error Handling

```swift
enum AppError: LocalizedError {
    case network(Error)
    case authentication(String)
    case storage(Error)
    case processing(String)
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .authentication(let message):
            return "Authentication failed: \(message)"
        case .storage(let error):
            return "Storage error: \(error.localizedDescription)"
        case .processing(let message):
            return "Processing error: \(message)"
        }
    }
}
```

### Offline-First Design

```swift
extension LessonService {
    func fetchLessons() async throws -> [Lesson] {
        // 1. Return cached data immediately
        let cachedLessons = try await coreDataManager.fetchLessons()
        
        // 2. Fetch fresh data in background
        Task {
            do {
                let remoteLessons = try await grpcClient.listLessons()
                try await coreDataManager.sync(remoteLessons)
            } catch {
                // Log error but don't fail - we have cached data
                logger.error("Failed to sync lessons: \(error)")
            }
        }
        
        return cachedLessons
    }
}
```

## Performance Guidelines

### SwiftUI Optimization
- Use `LazyVStack` and `LazyHStack` for lists
- Implement proper `Equatable` for view models
- Use `@StateObject` for view-owned objects
- Minimize `@Published` property updates
- Profile with Instruments regularly

### Memory Management
- Use weak references in delegates
- Clear caches on memory warnings
- Implement proper image caching
- Release resources in `onDisappear`
- Monitor memory usage in Debug Navigator

### Network Efficiency
- Batch API requests when possible
- Implement request coalescing
- Use streaming for real-time updates
- Cache responses appropriately
- Handle offline gracefully

## Security & Privacy

### Data Protection
- Store tokens in Keychain
- Encrypt Core Data store
- Use App Groups for extensions
- Implement App Check
- Clear sensitive data on logout

### Privacy Compliance
- Request permissions explicitly
- Provide clear privacy policy
- Implement data export/deletion
- Use on-device processing when possible
- Minimize data collection

## Testing Best Practices

### Unit Testing
```swift
final class LessonViewModelTests: XCTestCase {
    var sut: LessonViewModel!
    var mockService: MockLessonService!
    
    override func setUp() {
        super.setUp()
        mockService = MockLessonService()
        sut = LessonViewModel(lessonService: mockService)
    }
    
    func testLoadLessons() async {
        // Given
        let expectedLessons = [Lesson.fixture()]
        mockService.lessonsToReturn = expectedLessons
        
        // When
        await sut.loadLessons()
        
        // Then
        XCTAssertEqual(sut.lessons, expectedLessons)
        XCTAssertFalse(sut.isLoading)
    }
}
```

### UI Testing
```swift
final class LessonListUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    func testCreateLesson() {
        // Navigate to create lesson
        app.buttons["Add Lesson"].tap()
        
        // Fill form
        app.textFields["Title"].tap()
        app.textFields["Title"].typeText("Test Lesson")
        
        // Save
        app.buttons["Save"].tap()
        
        // Verify
        XCTAssertTrue(app.cells["Test Lesson"].exists)
    }
}
```

## Integration with Backend

### gRPC Setup
```swift
final class GRPCClientManager {
    static let shared = GRPCClientManager()
    
    lazy var client: ClassNotesServiceAsyncClient = {
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        let channel = try! GRPCChannelPool.with(
            target: .host(Config.apiHost, port: Config.apiPort),
            transportSecurity: .tls(GRPCTLSConfiguration.makeClientDefault()),
            eventLoopGroup: group
        )
        
        return ClassNotesServiceAsyncClient(
            channel: channel,
            interceptors: [AuthInterceptor(), LoggingInterceptor()]
        )
    }()
}
```

### Real-time Updates
```swift
func observeProcessingStatus(for documentID: String) async {
    do {
        let request = ProcessingStatusRequest(documentID: documentID)
        let stream = grpcClient.streamProcessingStatus(request)
        
        for try await status in stream {
            await MainActor.run {
                updateUI(with: status)
            }
        }
    } catch {
        logger.error("Stream error: \(error)")
    }
}
```

## Deployment Checklist

Before submitting to App Store:

- [ ] Test on all supported devices
- [ ] Verify offline functionality
- [ ] Check memory usage and performance
- [ ] Validate accessibility features
- [ ] Review crash logs and analytics
- [ ] Update version and build numbers
- [ ] Create App Store screenshots
- [ ] Write release notes
- [ ] Test in-app purchases (if any)
- [ ] Archive and validate build
- [ ] Submit for review with metadata

## Documentation Practices

### MANDATORY Documentation Guidelines

**1. Use Consolidated Documents**
- ✅ Add new information to existing consolidated documents
- ❌ DO NOT create new summary/status files for temporary updates
- ✅ Update `GRPC_SWIFT_V2_CONSOLIDATED.md` for all gRPC-related information
- ✅ Keep technical guides (setup, configuration) separate from status documents

**2. Version Control**
- ✅ Use git history for tracking changes
- ❌ DO NOT create multiple versions of the same document (e.g., v1, v2, FINAL, UPDATED)
- ✅ Use meaningful commit messages when updating documentation

**3. Documentation Structure**
```
Frontend/
├── README.md                              # Project overview & quick start
├── GRPC_SWIFT_V2_CONSOLIDATED.md         # All gRPC v2 information
├── SUBSCRIPTION_IMPLEMENTATION.md         # iOS subscription details
├── ClassNotes/
│   └── [Component]/README.md             # Component-specific docs
└── .cursorrules/                         # Development guidelines
```

**4. When to Create New Documents**
Only create new documentation files when:
- Introducing a completely new feature or system
- Creating a technical guide (setup, configuration, how-to)
- Documenting a new API or integration
- Writing component-specific documentation

**5. Quarterly Documentation Review**
- Review all documentation for redundancy
- Consolidate related documents
- Archive outdated information
- Update consolidated documents with recent changes

**6. Documentation Standards**
- Use clear, descriptive titles
- Include table of contents for long documents
- Add creation/update dates
- Cross-reference related documents
- Keep code examples up-to-date 