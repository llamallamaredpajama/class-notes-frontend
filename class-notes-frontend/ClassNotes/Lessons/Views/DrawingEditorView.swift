import SwiftUI
import PencilKit
import SwiftData

/// Full-featured drawing editor view for creating and editing drawings within a lesson
struct DrawingEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let lesson: Lesson
    let existingCanvas: DrawingCanvas?
    
    @State private var canvasView = PKCanvasView()
    @State private var isToolPickerActive = true
    @State private var canvasTitle = "New Drawing"
    @State private var showingColorPicker = false
    @State private var backgroundColor = Color.white
    @State private var showingSaveAlert = false
    @State private var hasUnsavedChanges = false
    
    init(lesson: Lesson, existingCanvas: DrawingCanvas? = nil) {
        self.lesson = lesson
        self.existingCanvas = existingCanvas
        
        if let canvas = existingCanvas {
            _canvasTitle = State(initialValue: canvas.title)
            _backgroundColor = State(initialValue: Color(hex: canvas.backgroundColor) ?? .white)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                PencilKitDrawingView(
                    canvasView: $canvasView,
                    isToolPickerActive: $isToolPickerActive,
                    isReadOnly: false
                )
                .onChange(of: canvasView.drawing) { _, _ in
                    hasUnsavedChanges = true
                }
            }
            .navigationTitle(canvasTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showingSaveAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDrawing()
                    }
                    .disabled(!hasUnsavedChanges)
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        showingColorPicker = true
                    } label: {
                        Image(systemName: "paintpalette")
                    }
                    
                    Spacer()
                    
                    Button {
                        isToolPickerActive.toggle()
                    } label: {
                        Image(systemName: isToolPickerActive ? "pencil.slash" : "pencil")
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            canvasView.drawing = PKDrawing()
                            hasUnsavedChanges = true
                        } label: {
                            Label("Clear Canvas", systemImage: "trash")
                        }
                        
                        Button {
                            shareDrawing()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerSheet(selectedColor: $backgroundColor)
            }
            .alert("Unsaved Changes", isPresented: $showingSaveAlert) {
                Button("Save", role: .none) {
                    saveDrawing()
                }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Would you like to save them before leaving?")
            }
            .onAppear {
                setupCanvas()
            }
        }
    }
    
    private func setupCanvas() {
        if let existingCanvas = existingCanvas,
           let drawing = try? PKDrawing(data: existingCanvas.canvasData) {
            canvasView.drawing = drawing
            hasUnsavedChanges = false
        }
    }
    
    private func saveDrawing() {
        let drawingData = canvasView.drawing.dataRepresentation()
        
        if let existingCanvas = existingCanvas {
            // Update existing canvas
            existingCanvas.canvasData = drawingData
            existingCanvas.title = canvasTitle
            existingCanvas.backgroundColor = backgroundColor.toHex() ?? "#FFFFFF"
            existingCanvas.touch()
            
            // Generate thumbnail
            if let thumbnail = generateThumbnail() {
                existingCanvas.thumbnailData = thumbnail
            }
        } else {
            // Create new canvas
            let newCanvas = DrawingCanvas(
                title: canvasTitle,
                canvasData: drawingData,
                width: canvasView.bounds.width,
                height: canvasView.bounds.height,
                backgroundColor: backgroundColor.toHex() ?? "#FFFFFF",
                lesson: lesson
            )
            
            // Generate thumbnail
            if let thumbnail = generateThumbnail() {
                newCanvas.thumbnailData = thumbnail
            }
            
            modelContext.insert(newCanvas)
            lesson.drawingCanvases.append(newCanvas)
        }
        
        do {
            try modelContext.save()
            hasUnsavedChanges = false
            dismiss()
        } catch {
            print("Failed to save drawing: \(error)")
        }
    }
    
    private func generateThumbnail() -> Data? {
        let scale: CGFloat = 0.25
        let image = canvasView.drawing.image(
            from: canvasView.drawing.bounds,
            scale: scale
        )
        return image.jpegData(compressionQuality: 0.8)
    }
    
    private func shareDrawing() {
        let image = canvasView.drawing.image(
            from: canvasView.drawing.bounds,
            scale: UIScreen.main.scale
        )
        
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

/// Color picker sheet for background color selection
struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: Color
    
    let colors: [Color] = [
        .white, .gray, .black,
        .red, .orange, .yellow,
        .green, .mint, .cyan,
        .blue, .indigo, .purple,
        .pink, .brown
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            selectedColor = color
                            dismiss()
                        } label: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(color)
                                .frame(height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 3)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Background Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview("Drawing Editor - New Canvas") {
    NavigationStack {
        if let sampleLesson = MockData.sampleLessons.first {
            DrawingEditorView(lesson: sampleLesson)
        }
    }
    .modelContainer(PersistenceController.preview.container)
}

#Preview("Drawing Editor - Existing Canvas") {
    NavigationStack {
        if let sampleLesson = MockData.sampleLessons.first {
            let existingCanvas = DrawingCanvas(
                title: "Sample Drawing",
                canvasData: Data(),
                lesson: sampleLesson
            )
            DrawingEditorView(lesson: sampleLesson, existingCanvas: existingCanvas)
        }
    }
    .modelContainer(PersistenceController.preview.container)
} 