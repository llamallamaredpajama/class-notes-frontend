import Foundation
import SwiftData

/// Represents an authenticated user in the app
@Model
final class User {
    /// Unique identifier for the user
    @Attribute(.unique) var id: UUID
    
    /// User's email address
    var email: String
    
    /// User's display name
    var displayName: String
    
    /// User's profile image URL
    var profileImageURL: URL?
    
    /// Authentication provider (e.g., "google", "apple")
    var authProvider: String
    
    /// Date when the user account was created
    var createdAt: Date
    
    /// Date when the user last signed in
    var lastSignInAt: Date
    
    /// User preferences
    var preferences: UserPreferences?
    
    init(
        id: UUID = UUID(),
        email: String,
        displayName: String,
        profileImageURL: URL? = nil,
        authProvider: String
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.authProvider = authProvider
        self.createdAt = Date()
        self.lastSignInAt = Date()
    }
}

/// User preferences stored with the user profile
@Model
final class UserPreferences {
    /// Unique identifier
    @Attribute(.unique) var id: UUID
    
    /// Preferred theme
    var theme: String
    
    /// Whether to use haptic feedback
    var useHapticFeedback: Bool
    
    /// Preferred text size
    var preferredTextSize: String
    
    /// Whether to enable audio transcription by default
    var autoTranscribe: Bool
    
    /// Preferred language for transcription
    var transcriptionLanguage: String
    
    init(
        theme: String = "system",
        useHapticFeedback: Bool = true,
        preferredTextSize: String = "medium",
        autoTranscribe: Bool = true,
        transcriptionLanguage: String = "en-US"
    ) {
        self.id = UUID()
        self.theme = theme
        self.useHapticFeedback = useHapticFeedback
        self.preferredTextSize = preferredTextSize
        self.autoTranscribe = autoTranscribe
        self.transcriptionLanguage = transcriptionLanguage
    }
} 