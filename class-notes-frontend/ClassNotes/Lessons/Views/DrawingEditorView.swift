import SwiftData
import SwiftUI

#if os(iOS)
    import PencilKit
    import UIKit

    /// Full-featured drawing editor view for creating and editing drawings within a lesson
    struct DrawingEditorView: View {
        // MARK: - Properties
        
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

        // MARK: - Initialization
        
        init(lesson: Lesson, existingCanvas: DrawingCanvas? = nil) {
            self.lesson = lesson
            self.existingCanvas = existingCanvas

            if let canvas = existingCanvas {
                _canvasTitle = State(initialValue: canvas.title)
                _backgroundColor = State(initialValue: Color(hex: canvas.backgroundColor) ?? .white)
            }
        }

        // MARK: - Body
        
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
                    navigationToolbar
                    bottomToolbar
                }
                .sheet(isPresented: $showingColorPicker) {
                    ColorPickerSheet(selectedColor: $backgroundColor)
                }
                .alert("Unsaved Changes", isPresented: $showingSaveAlert) {
                    unsavedChangesButtons
                } message: {
                    Text("You have unsaved changes. Would you like to save them before leaving?")
                }
                .onAppear {
                    setupCanvas()
                }
            }
        }

        // MARK: - Views
        
        @ToolbarContentBuilder
        private var navigationToolbar: some ToolbarContent {
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
        }
        
        @ToolbarContentBuilder
        private var bottomToolbar: some ToolbarContent {
            ToolbarItemGroup(placement: .bottomBar) {
                colorPickerButton
                Spacer()
                toolPickerToggle
                Spacer()
                moreOptionsMenu
            }
        }
        
        private var colorPickerButton: some View {
            Button {
                showingColorPicker = true
            } label: {
                Image(systemName: "paintpalette")
            }
        }
        
        private var toolPickerToggle: some View {
            Button {
                isToolPickerActive.toggle()
            } label: {
                Image(systemName: isToolPickerActive ? "pencil.slash" : "pencil")
            }
        }
        
        private var moreOptionsMenu: some View {
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
        
        @ViewBuilder
        private var unsavedChangesButtons: some View {
            Button("Save", role: .none) {
                saveDrawing()
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }

        // MARK: - Methods
        
        private func setupCanvas() {
            if let existingCanvas = existingCanvas,
                let drawing = try? PKDrawing(data: existingCanvas.canvasData)
            {
                canvasView.drawing = drawing
                hasUnsavedChanges = false
            }
        }

        private func saveDrawing() {
            let drawingData = canvasView.drawing.dataRepresentation()

            if let existingCanvas = existingCanvas {
                updateExistingCanvas(existingCanvas, with: drawingData)
            } else {
                createNewCanvas(with: drawingData)
            }

            do {
                try modelContext.save()
                hasUnsavedChanges = false
                dismiss()
            } catch {
                print("Failed to save drawing: \(error)")
            }
        }
        
        private func updateExistingCanvas(_ canvas: DrawingCanvas, with data: Data) {
            canvas.canvasData = data
            canvas.title = canvasTitle
            canvas.backgroundColor = backgroundColor.toHex() ?? "#FFFFFF"
            canvas.touch()

            if let thumbnail = generateThumbnail() {
                canvas.thumbnailData = thumbnail
            }
        }
        
        private func createNewCanvas(with data: Data) {
            let newCanvas = DrawingCanvas(
                title: canvasTitle,
                canvasData: data,
                width: canvasView.bounds.width,
                height: canvasView.bounds.height,
                backgroundColor: backgroundColor.toHex() ?? "#FFFFFF",
                lesson: lesson
            )

            if let thumbnail = generateThumbnail() {
                newCanvas.thumbnailData = thumbnail
            }

            modelContext.insert(newCanvas)
            lesson.drawingCanvases.append(newCanvas)
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
                let rootVC = windowScene.windows.first?.rootViewController
            {
                rootVC.present(activityVC, animated: true)
            }
        }
    }

    /// Color picker sheet for background color selection
    struct ColorPickerSheet: View {
        // MARK: - Properties
        
        @Environment(\.dismiss) private var dismiss
        @Binding var selectedColor: Color

        let colors: [Color] = [
            .white, .gray, .black,
            .red, .orange, .yellow,
            .green, .mint, .cyan,
            .blue, .indigo, .purple,
            .pink, .brown,
        ]

        // MARK: - Body
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    colorGrid
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
        
        // MARK: - Views
        
        private var colorGrid: some View {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20
            ) {
                ForEach(colors, id: \.self) { color in
                    colorButton(for: color)
                }
            }
            .padding()
        }
        
        private func colorButton(for color: Color) -> some View {
            Button {
                selectedColor = color
                dismiss()
            } label: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                selectedColor == color ? Color.blue : Color.clear,
                                lineWidth: 3)
                    )
            }
        }
    }

#else
    // Placeholder for non-iOS platforms
    struct DrawingEditorView: View {
        // MARK: - Properties
        
        let lesson: Lesson
        let existingCanvas: DrawingCanvas?

        // MARK: - Initialization
        
        init(lesson: Lesson, existingCanvas: DrawingCanvas? = nil) {
            self.lesson = lesson
            self.existingCanvas = existingCanvas
        }

        // MARK: - Body
        
        var body: some View {
            VStack {
                Image(systemName: "pencil.tip.crop.circle.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Drawing editor is only available on iOS/iPadOS")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            .navigationTitle("Drawing Editor")
        }
    }

    struct ColorPickerSheet: View {
        @Binding var selectedColor: Color

        var body: some View {
            EmptyView()
        }
    }
#endif

// MARK: - Preview

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
