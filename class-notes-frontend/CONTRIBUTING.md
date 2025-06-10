# Contributing to Class Notes

Thank you for your interest in contributing to Class Notes! We welcome contributions from the community.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/class-notes-frontend.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Commit with descriptive messages: `git commit -m "Add: your feature description"`
6. Push to your fork: `git push origin feature/your-feature-name`
7. Open a Pull Request

## Development Setup

1. Ensure you have Xcode 15.0+ installed
2. Clone the repository
3. Open `ClassNotes.xcodeproj` in Xcode
4. Add required configuration files (see README.md)
5. Build and run

## Code Style Guidelines

- Follow Swift API Design Guidelines
- Use SwiftLint (configuration included)
- Maintain consistent naming conventions
- Document public APIs with DocC comments

## Architecture Guidelines

- Follow MVVM pattern with `@MainActor` for ViewModels
- Use protocol-oriented design
- Implement proper dependency injection
- Keep views declarative and logic-free

## Pull Request Process

1. Ensure your code follows the style guidelines
2. Update documentation as needed
3. Add tests for new functionality
4. Verify all tests pass
5. Update the README.md if needed
6. Request review from maintainers

## Commit Message Format

Use clear, descriptive commit messages:
- `Add:` for new features
- `Fix:` for bug fixes
- `Update:` for changes to existing features
- `Remove:` for removed features
- `Refactor:` for code improvements
- `Docs:` for documentation changes

## Testing

- Write unit tests for ViewModels
- Add UI tests for critical user flows
- Test accessibility features
- Verify on both iPhone and iPad

## Accessibility

All contributions must maintain accessibility standards:
- Add proper VoiceOver labels
- Support Dynamic Type
- Test with VoiceOver enabled
- Provide keyboard navigation where applicable

## Questions?

Feel free to open an issue for any questions or discussions about contributing.

Thank you for helping make Class Notes better! 