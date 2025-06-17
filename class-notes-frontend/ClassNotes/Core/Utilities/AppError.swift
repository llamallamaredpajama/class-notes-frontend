// 1. Standard library
import Foundation

/// Unified error type for the application
enum AppError: LocalizedError {
    case network(Error)
    case authentication(String)
    case storage(Error)
    case processing(String)
    case audio(String)
    case lesson(String)

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
        case .audio(let message):
            return "Audio error: \(message)"
        case .lesson(let message):
            return "Lesson error: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .network:
            return "Please check your internet connection and try again."
        case .authentication:
            return "Please sign in again to continue."
        case .storage:
            return "Please check available storage space and try again."
        case .processing:
            return "Please try again later."
        case .audio:
            return "Please check your microphone permissions and try again."
        case .lesson:
            return "Please try refreshing the lesson."
        }
    }
}

// MARK: - Convenience Initializers
extension AppError {
    /// Initialize from a generic error
    init(_ error: Error) {
        if let nsError = error as NSError? {
            switch nsError.domain {
            case NSURLErrorDomain:
                self = .network(error)
            case NSCocoaErrorDomain where nsError.code == NSFileWriteOutOfSpaceError:
                self = .storage(error)
            default:
                self = .processing(error.localizedDescription)
            }
        } else {
            self = .processing(error.localizedDescription)
        }
    }
}
