import SwiftUI

/// Available colors for courses
enum CourseColor: String, CaseIterable, Codable {
    case blue = "#007AFF"
    case green = "#34C759"
    case orange = "#FF9500"
    case red = "#FF3B30"
    case purple = "#AF52DE"
    case pink = "#FF2D55"
    case teal = "#5AC8FA"
    case indigo = "#5856D6"
    case brown = "#A2845E"
    case gray = "#8E8E93"
    
    /// SwiftUI Color representation
    var swiftUIColor: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        case .brown: return .brown
        case .gray: return .gray
        }
    }
    
    /// Hex string value
    var hexString: String {
        rawValue
    }
    
    /// Initialize from hex string
    init?(hexString: String) {
        self.init(rawValue: hexString)
    }
} 