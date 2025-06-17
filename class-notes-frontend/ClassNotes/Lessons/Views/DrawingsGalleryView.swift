import SwiftUI

#if os(iOS)
    import PencilKit
    import UIKit

    /// Gallery view displaying all drawings for a lesson
    struct DrawingsGalleryView: View {
        // MARK: - Properties
        
        let lesson: Lesson
        @State private var selectedCanvas: DrawingCanvas?
        @State private var showingNewDrawing = false
        @State private var showingViewer = false

        private let columns = [
            GridItem(.adaptive(minimum: 150), spacing: 16)
        ]

        // MARK: - Body
        
        var body: some View {
            ScrollView {
                if lesson.drawingCanvases.isEmpty {
                    emptyStateView
                } else {
                    drawingsGrid
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

        // MARK: - Views
        
        private var drawingsGrid: some View {
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
        // MARK: - Properties
        
        let canvas: DrawingCanvas

        private var canvasBackgroundColor: Color {
            Color(hex: canvas.backgroundColor) ?? .white
        }

        // MARK: - Body
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                thumbnailImage
                metadata
            }
        }

        // MARK: - Views
        
        private var thumbnailImage: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(canvasBackgroundColor)
                    .aspectRatio(canvas.aspectRatio, contentMode: .fit)

                thumbnailContent

                if canvas.isLocked {
                    lockOverlay
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.5, opacity: 0.2), lineWidth: 1)
            )
        }
        
        @ViewBuilder
        private var thumbnailContent: some View {
            if let thumbnailData = canvas.thumbnailData,
                let uiImage = UIImage(data: thumbnailData)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "pencil.tip.crop.circle")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
        }
        
        private var lockOverlay: some View {
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
        
        private var metadata: some View {
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

    /// Viewer for displaying and editing a drawing
    struct DrawingViewerView: View {
        // MARK: - Properties
        
        @Environment(\.dismiss) private var dismiss
        let lesson: Lesson
        let canvas: DrawingCanvas

        @State private var canvasView = PKCanvasView()
        @State private var showingEditor = false
        @State private var isToolPickerActive = false

        private var canvasBackgroundColor: Color {
            Color(hex: canvas.backgroundColor) ?? .white
        }

        // MARK: - Body
        
        var body: some View {
            NavigationStack {
                ZStack {
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
                    toolbarContent
                }
                .onAppear {
                    setupCanvas()
                }
            }
            .fullScreenCover(isPresented: $showingEditor) {
                DrawingEditorView(lesson: lesson, existingCanvas: canvas)
            }
        }
        
        // MARK: - Views
        
        @ToolbarContentBuilder
        private var toolbarContent: some ToolbarContent {
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
        
        // MARK: - Methods
        
        private func setupCanvas() {
            if let drawing = try? PKDrawing(data: canvas.canvasData) {
                canvasView.drawing = drawing
            }
        }
    }

    // MARK: - Preview
    
    #Preview {
        NavigationStack {
            if let sampleLesson = MockData.sampleLessons.first {
                DrawingsGalleryView(lesson: sampleLesson)
            }
        }
        .modelContainer(PersistenceController.preview.container)
    }

#else
    // MARK: - Non-iOS Placeholder
    
    struct DrawingsGalleryView: View {
        // MARK: - Properties
        
        let lesson: Lesson

        // MARK: - Body
        
        var body: some View {
            VStack {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Drawing gallery is only available on iOS/iPadOS")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            .navigationTitle("Drawings")
        }
    }

    struct DrawingThumbnailView: View {
        let canvas: DrawingCanvas
        var body: some View { EmptyView() }
    }

    struct DrawingViewerView: View {
        let lesson: Lesson
        let canvas: DrawingCanvas
        var body: some View { EmptyView() }
    }
#endif


