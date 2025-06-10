import SwiftUI
import PencilKit

/// Gallery view displaying all drawings for a lesson
struct DrawingsGalleryView: View {
    let lesson: Lesson
    @State private var selectedCanvas: DrawingCanvas?
    @State private var showingNewDrawing = false
    @State private var showingViewer = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            if lesson.drawingCanvases.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(lesson.drawingCanvases.sorted(by: { $0.createdAt > $1.createdAt })) { canvas in
                        DrawingThumbnailView(canvas: canvas)
                            .onTapGesture {
                                selectedCanvas = canvas
                                showingViewer = true
                            }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Drawings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingNewDrawing = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewDrawing) {
            DrawingEditorView(lesson: lesson)
        }
        .sheet(item: $selectedCanvas) { canvas in
            DrawingViewerView(lesson: lesson, canvas: canvas)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Drawings Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to create your first drawing")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingNewDrawing = true
            } label: {
                Label("Create Drawing", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

/// Thumbnail view for a drawing canvas
struct DrawingThumbnailView: View {
    let canvas: DrawingCanvas
    
    private var canvasBackgroundColor: Color {
        // Convert hex string to Color, defaulting to white if conversion fails
        let hex = canvas.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return .white
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(canvasBackgroundColor)
                    .aspectRatio(canvas.aspectRatio, contentMode: .fit)
                
                if let thumbnailData = canvas.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "pencil.tip.crop.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
                
                if canvas.isLocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.5, opacity: 0.2), lineWidth: 1)
            )
            
            // Title and metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(canvas.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(canvas.formattedLastModifiedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Viewer for displaying and editing a drawing
struct DrawingViewerView: View {
    @Environment(\.dismiss) private var dismiss
    let lesson: Lesson
    let canvas: DrawingCanvas
    
    @State private var canvasView = PKCanvasView()
    @State private var showingEditor = false
    @State private var isToolPickerActive = false
    
    private var canvasBackgroundColor: Color {
        // Convert hex string to Color, defaulting to white if conversion fails
        let hex = canvas.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return .white
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Rectangle()
                    .fill(canvasBackgroundColor)
                    .ignoresSafeArea()
                
                PencilKitDrawingView(
                    canvasView: $canvasView,
                    isToolPickerActive: $isToolPickerActive,
                    isReadOnly: true
                )
            }
            .navigationTitle(canvas.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditor = true
                    }
                    .disabled(canvas.isLocked)
                }
            }
            .onAppear {
                if let drawing = try? PKDrawing(data: canvas.canvasData) {
                    canvasView.drawing = drawing
                }
            }
        }
        .fullScreenCover(isPresented: $showingEditor) {
            DrawingEditorView(lesson: lesson, existingCanvas: canvas)
        }
    }
}

#Preview {
    NavigationStack {
        if let sampleLesson = MockData.sampleLessons.first {
            DrawingsGalleryView(lesson: sampleLesson)
        }
    }
    .modelContainer(PersistenceController.preview.container)
} 