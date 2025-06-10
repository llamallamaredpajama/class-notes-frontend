# Cursor + Xcode Workflow Improvements

This document describes the workflow optimization tools and configurations that have been added to improve hybrid Cursor + Xcode development.

## 🚀 Quick Start

Run the quick start script to see all available tools:
```bash
./Scripts/quick-start.sh
```

## 📁 New Structure Added

### 1. **Cursor Configuration** (`.cursor/`)
- `settings.json` - Cursor IDE settings optimized for Swift development
- Configures AI provider, file associations, and context includes
- Excludes unnecessary files like DerivedData

### 2. **Build Automation** (`Scripts/`)
- `xcode-build.sh` - Build the project without switching to Xcode
- `run-tests.sh` - Run tests from command line
- `quick-start.sh` - Interactive guide for new developers

### 3. **Development Helpers** (`ClassNotes/Core/Development/`)
- `PreviewHelpers.swift` - Mock data and SwiftUI preview extensions
- `DebugView.swift` - Component gallery for testing without full app context
- `DebugOverlay.swift` - Visual debugging tools (memory, device info, grid overlay)

### 4. **Logging Infrastructure** (`ClassNotes/Core/Utilities/`)
- `Logger+Extensions.swift` - Structured logging with OSLog
- Category-based loggers (authentication, lessons, networking, etc.)
- Performance tracking and debug utilities

### 5. **ViewModels** (`ClassNotes/Lessons/ViewModels/`)
- `LessonListViewModel.swift` - List management with search and sort
- `LessonDetailViewModel.swift` - Recording and transcription management

### 6. **Protocols** (`ClassNotes/Core/Protocols/`)
- `LessonServiceProtocol.swift` - Lesson operations interface
- `AudioServiceProtocol.swift` - Audio recording interface

## 🛠️ Development Workflow

### Primary Development in Cursor
1. Open project in Cursor: `cursor .`
2. Edit Swift files with syntax highlighting
3. Use AI assistance for code generation
4. View logs in terminal

### Building and Testing
```bash
# Build the project
./Scripts/xcode-build.sh

# Run tests
./Scripts/run-tests.sh

# View logs
log stream --predicate 'subsystem == "com.classnotes.app"'
```

### Debug Mode Development
1. Use `DebugView.swift` to test components in isolation
2. Add `.debugOverlay()` to any view for performance metrics
3. Access component gallery through debug tabs

### Using Preview Helpers
```swift
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
            .previewAsComponent()
            .previewColorSchemes()
    }
}
```

### Logging Examples
```swift
// Feature logging
Logger.lessons.info("Loaded \(lessons.count) lessons")
Logger.authentication.error("Sign-in failed: \(error)")

// Network logging
Logger.networking.networkRequest("GET", url: apiURL)
Logger.networking.networkResponse(200, url: apiURL, duration: 0.234)

// Debug milestones
Logger.debug.milestone("App launched")
```

## 🔍 Debug Features

### Visual Debugging
- **Debug Overlay**: Shows device info, memory usage, and performance metrics
- **Grid Overlay**: Alignment grid for UI debugging
- **Touch Indicators**: Visual feedback for touch interactions

### Component Gallery
Access through `DebugView` tabs:
- Current development focus
- Authentication testing
- Component showcase
- Debug settings

### Mock Data
Use `MockData` struct for consistent test data:
- `MockData.sampleLesson`
- `MockData.sampleLessons`
- `MockData.sampleUser`
- `MockData.sampleError`

## 📋 Best Practices

1. **Use Protocols**: All services should have protocol definitions
2. **Mock Implementations**: Provide mock versions for testing
3. **Structured Logging**: Use appropriate logger categories
4. **Preview Support**: Add preview providers for all views
5. **Debug Builds**: Wrap debug code in `#if DEBUG`

## 🔗 Integration with Backend

The project maintains compatibility with the Go backend at:
https://github.com/Fuku-Solutions/class-notes-backend.git

All service protocols are designed to work with gRPC communication.

## 📚 Additional Resources

- See `ARCHITECTURE.md` for overall project structure
- Check individual file headers for usage examples
- Run `./Scripts/quick-start.sh` for interactive help 