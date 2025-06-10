# Class Notes - AI-Powered Learning Companion

Class Notes is an iOS/iPadOS educational app that helps students take smarter notes and learn more effectively using AI-powered features.

## Features

- **Smart Note Taking**: Create and organize notes with AI assistance
- **Audio Recording & Transcription**: Record lectures and get automatic transcriptions
- **Drawing Canvas**: Sketch diagrams and visual notes
- **Course Organization**: Organize lessons by courses and track progress
- **Accessibility First**: Full VoiceOver support and Dynamic Type

## Architecture

The app follows clean architecture principles with:

- **MVVM Pattern**: ViewModels with `@MainActor` for UI updates
- **Protocol-Oriented Design**: All major components have protocol definitions
- **Dependency Injection**: Environment-based DI for all services
- **SwiftData**: Modern persistence with iCloud sync
- **Secure Storage**: Keychain for sensitive data

## Project Structure

```
ClassNotes/
├── App/                    # App entry point and configuration
├── Authentication/         # Sign-in and user management
│   ├── ViewModels/
│   ├── Views/
│   ├── Services/
│   └── Models/
├── Lessons/               # Core lesson functionality
│   ├── Views/
│   └── Models/
└── Core/                  # Shared utilities and services
    ├── Storage/
    ├── Services/
    └── Protocols/
```

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ / iPadOS 17.0+
- Google Sign-In configuration

### Setup

1. Clone the repository
2. Open `ClassNotes.xcodeproj` in Xcode
3. Add your `GoogleService-Info.plist` file
4. Configure your OAuth client IDs (see `CONFIGURE_OAUTH_IDS.md`)
5. Build and run

### Dependencies

- **GoogleSignIn**: Authentication
- **gRPC Swift**: Backend communication
- **Swift Async Algorithms**: Data processing
- **KeychainAccess**: Secure storage

## Development Guidelines

### Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable names
- Keep functions under 30 lines
- Document public APIs with DocC comments

### Architecture Rules

1. **ViewModels**: Always use `@MainActor` for UI-related ViewModels
2. **Services**: Define protocols for all services
3. **Models**: Use UUID identifiers for all SwiftData models
4. **Views**: Keep views declarative and logic-free

### Security

- Never store sensitive data in UserDefaults
- Use Keychain for authentication tokens
- Validate all user inputs
- Implement certificate pinning for network requests

### Accessibility

- Add accessibility labels and hints to all interactive elements
- Support Dynamic Type for all text
- Test with VoiceOver enabled
- Provide alternatives for visual-only information

## Testing

Run tests with:
```bash
xcodebuild test -scheme ClassNotes -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Contributing

1. Follow the existing code structure
2. Write tests for new features
3. Update documentation as needed
4. Ensure accessibility compliance

## License

[Add your license information here]

## Acknowledgments

- Built with SwiftUI and SwiftData
- Uses Google Sign-In for authentication
- AI features powered by [Your AI provider] 