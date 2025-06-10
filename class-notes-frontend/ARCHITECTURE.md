# Class Notes Frontend Architecture

## Overview
Class Notes is an AI-powered educational app built with SwiftUI for iOS/iPadOS with planned macOS support. The app enables students to record lectures, get real-time transcriptions, and generate comprehensive study materials.

## Technology Stack
- **UI Framework**: SwiftUI (iOS 17+, iPadOS 17+, macOS 14+)
- **Architecture**: MVVM with @MainActor
- **Backend Communication**: gRPC-Swift
- **Authentication**: Google Sign-In
- **Storage**: Core Data + File Provider Extension
- **Audio Processing**: WhisperKit (planned)
- **Backend**: Go 1.24 microservices (https://github.com/Fuku-Solutions/class-notes-backend.git)

## Project Structure
```
class-notes-frontend/
├── .cursor/                     # Cursor IDE configuration
│   └── settings.json           # Editor and AI settings
├── Scripts/                     # Build automation scripts
│   ├── xcode-build.sh          # Build without switching to Xcode
│   └── run-tests.sh            # Run tests from command line
├── ClassNotes/                  # Main app code
│   ├── App/                    # App entry point and configuration
│   ├── Authentication/         # Google Sign-In integration
│   │   ├── Models/            # User models
│   │   ├── Services/          # Auth service layer
│   │   ├── ViewModels/        # Auth view models
│   │   └── Views/             # Sign-in UI
│   ├── Core/                   # Shared components and utilities
│   │   ├── Development/       # Debug tools and preview helpers
│   │   │   ├── DebugView.swift
│   │   │   ├── PreviewHelpers.swift
│   │   │   └── DebugOverlay.swift
│   │   ├── Protocols/         # Protocol definitions
│   │   ├── Services/          # Core services (networking, storage)
│   │   ├── Storage/           # Core Data and file management
│   │   └── Utilities/         # Logging, extensions, helpers
│   └── Lessons/               # Lesson recording and management
│       ├── Models/            # Lesson data models
│       ├── ViewModels/        # Lesson view models
│       └── Views/             # Lesson UI components
└── Assets.xcassets/           # App icons and images
```

## Key Features
1. **Real-time Audio Transcription**
   - WhisperKit integration for on-device transcription
   - Background audio recording support
   - Automatic silence detection

2. **PDF Generation and Annotation**
   - Convert transcripts to formatted PDFs
   - Support for annotations and highlights
   - Export to Files app

3. **Cloud Synchronization**
   - gRPC communication with Go backend
   - Automatic sync when connected
   - Conflict resolution

4. **Offline Support**
   - Core Data for local storage
   - Queue system for pending uploads
   - Seamless online/offline transitions

## Architecture Patterns

### MVVM with @MainActor
All ViewModels follow this pattern:
```swift
@MainActor
class FeatureViewModel: ObservableObject {
    @Published private(set) var state: FeatureState
    private let service: FeatureServiceProtocol
    
    func performAction() async {
        // Async operations
    }
}
```

### Service Layer
- Protocol-based design for testability
- Separate implementations for real and mock services
- Dependency injection through initializers

### Error Handling
- Structured error types for each domain
- User-friendly error messages
- Retry mechanisms for network operations

## Development Workflow

### Cursor + Xcode Hybrid Development
1. **Primary Development**: Use Cursor for coding
2. **Building/Testing**: Use Xcode or Scripts/ automation
3. **Debugging**: DebugView.swift for quick iteration

### Debug Tools
- `DebugView.swift`: Test components without full app context
- `PreviewHelpers.swift`: Mock data and preview extensions
- `DebugOverlay.swift`: Visual debugging information

### Build Scripts
- `Scripts/xcode-build.sh`: Build from command line
- `Scripts/run-tests.sh`: Run tests without opening Xcode

## Backend Integration

### gRPC Services
- Generated Swift code from .proto files
- Async/await based API calls
- Automatic retry and error handling

### Authentication Flow
1. Google Sign-In on client
2. Token exchange with backend
3. Session management with refresh tokens

## Performance Considerations
- Lazy loading for lesson lists
- Image caching for thumbnails
- Background processing for audio
- Efficient Core Data queries

## Security
- Keychain storage for sensitive data
- Certificate pinning for API calls
- Encrypted local storage
- Secure token handling

## Testing Strategy
- Unit tests for ViewModels and Services
- UI tests for critical user flows
- Preview-based development for rapid iteration
- Mock services for testing edge cases

## Future Enhancements
- macOS Catalyst support
- Apple Watch companion app
- Siri Shortcuts integration
- Widget support for quick access 