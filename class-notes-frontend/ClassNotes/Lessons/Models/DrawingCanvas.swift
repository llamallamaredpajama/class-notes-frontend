import Foundation
import SwiftData
import CoreGraphics

/// Represents a drawing canvas in a lesson
@Model
final class DrawingCanvas {
    /// Unique identifier for the canvas
    @Attribute(.unique) var id: UUID
    
    /// Title of the canvas
    var title: String
    
    /// Canvas data (serialized drawing data)
    var canvasData: Data
    
    /// Thumbnail image data
    var thumbnailData: Data?
    
    /// Canvas dimensions
    var width: CGFloat
    var height: CGFloat
    
    /// Background color (hex string)
    var backgroundColor: String
    
    /// Date when the canvas was created
    var createdAt: Date
    
    /// Date when the canvas was last modified
    var lastModified: Date
    
    /// Whether the canvas is locked for editing
    var isLocked: Bool
    
    /// Tags for categorization
    var tags: [String]
    
    // MARK: - Relationships
    
    /// The lesson this canvas belongs to
    var lesson: Lesson?
    
    // MARK: - Initialization
    
    init(
        title: String,
        canvasData: Data = Data(),
        width: CGFloat = 1024,
        height: CGFloat = 768,
        backgroundColor: String = "#FFFFFF",
        lesson: Lesson? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.canvasData = canvasData
        self.width = width
        self.height = height
        self.backgroundColor = backgroundColor
        self.createdAt = Date()
        self.lastModified = Date()
        self.isLocked = false
        self.tags = []
        self.lesson = lesson
    }
}

/// Drawing stroke data structure
struct DrawingStroke: Codable {
    let points: [CGPoint]
    let color: String
    let lineWidth: CGFloat
    let opacity: Double
    let tool: DrawingTool
    let timestamp: Date
}

/// Drawing tool types
enum DrawingTool: String, Codable, CaseIterable {
    case pen = "pen"
    case pencil = "pencil"
    case marker = "marker"
    case highlighter = "highlighter"
    case eraser = "eraser"
    case line = "line"
    case rectangle = "rectangle"
    case circle = "circle"
    case arrow = "arrow"
    case text = "text"
    
    var displayName: String {
        switch self {
        case .pen:
            return "Pen"
        case .pencil:
            return "Pencil"
        case .marker:
            return "Marker"
        case .highlighter:
            return "Highlighter"
        case .eraser:
            return "Eraser"
        case .line:
            return "Line"
        case .rectangle:
            return "Rectangle"
        case .circle:
            return "Circle"
        case .arrow:
            return "Arrow"
        case .text:
            return "Text"
        }
    }
    
    var iconName: String {
        switch self {
        case .pen:
            return "pencil"
        case .pencil:
            return "pencil.tip"
        case .marker:
            return "paintbrush.pointed"
        case .highlighter:
            return "highlighter"
        case .eraser:
            return "eraser"
        case .line:
            return "line.diagonal"
        case .rectangle:
            return "rectangle"
        case .circle:
            return "circle"
        case .arrow:
            return "arrow.up.right"
        case .text:
            return "textformat"
        }
    }
    
    var defaultLineWidth: CGFloat {
        switch self {
        case .pen:
            return 2.0
        case .pencil:
            return 1.5
        case .marker:
            return 5.0
        case .highlighter:
            return 15.0
        case .eraser:
            return 20.0
        case .line, .rectangle, .circle, .arrow:
            return 2.0
        case .text:
            return 0.0
        }
    }
}

// MARK: - Extensions

extension DrawingCanvas {
    /// Formatted creation date
    var formattedCreatedDate: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }
    
    /// Formatted last modified date
    var formattedLastModifiedDate: String {
        lastModified.formatted(date: .abbreviated, time: .shortened)
    }
    
    /// Canvas aspect ratio
    var aspectRatio: CGFloat {
        guard height > 0 else { return 1.0 }
        return width / height
    }
    
    /// Update the last modified date
    func touch() {
        lastModified = Date()
    }
    
    /// Decode drawing strokes from canvas data
    func getStrokes() -> [DrawingStroke]? {
        try? JSONDecoder().decode([DrawingStroke].self, from: canvasData)
    }
    
    /// Encode drawing strokes to canvas data
    func setStrokes(_ strokes: [DrawingStroke]) {
        if let data = try? JSONEncoder().encode(strokes) {
            canvasData = data
            touch()
        }
    }
} 