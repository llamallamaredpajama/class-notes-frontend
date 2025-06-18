import SwiftUI
import PencilKit
import UniformTypeIdentifiers

#if os(iOS)
    import UIKit

    /// Enhanced gallery view displaying all drawings for a lesson with management features
    struct DrawingsGalleryView: View {
        // MARK: - Properties
        
        @Environment(\.modelContext) private var modelContext
        @Environment(\.editMode) private var editMode
        
        let lesson: Lesson
        
        @State private var selectedCanvas: DrawingCanvas?
        @State private var showingNewDrawing = false
        @State private var showingViewer = false
        @State private var selectedDrawings: Set<DrawingCanvas> = []
        @State private var showingExportOptions = false
        @State private var showingDeleteConfirmation = false
        @State private var sortOrder: DrawingSortOrder = .dateDescending
        @State private var viewMode: GalleryViewMode = .grid
        
        private var sortedDrawings: [DrawingCanvas] {
            let drawings = lesson.drawings ?? []
            return drawings.sorted { first, second in
                switch sortOrder {
                case .dateDescending:
                    return first.createdAt > second.createdAt
                case .dateAscending:
                    return first.createdAt < second.createdAt
                case .nameAscending:
                    return first.title < second.title
                case .nameDescending:
                    return first.title > second.title
                }
            }
        }
        
        private let gridColumns = [
            GridItem(.adaptive(minimum: 150), spacing: 16)
        ]

        // MARK: - Body
        
        var body: some View {
            NavigationStack {
                Group {
                    if lesson.drawings?.isEmpty ?? true {
                        emptyStateView
                    } else {
                        drawingsContent
                    }
                }
                .navigationTitle("Drawings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showingNewDrawing) {
                    NavigationStack {
                        DrawingCanvasView(lesson: lesson, drawingCanvas: nil, onSave: nil)
                    }
                }
                .sheet(item: $selectedCanvas) { canvas in
                    DrawingDetailView(lesson: lesson, canvas: canvas)
                }
                .confirmationDialog("Export Drawings", isPresented: $showingExportOptions) {
                    Button("Export as PDF") {
                        exportSelectedAsPDF()
                    }
                    Button("Export as Images") {
                        exportSelectedAsImages()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Choose export format for \(selectedDrawings.count) drawing(s)")
                }
                .confirmationDialog("Delete Drawings?", isPresented: $showingDeleteConfirmation) {
                    Button("Delete", role: .destructive) {
                        deleteSelectedDrawings()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Delete \(selectedDrawings.count) drawing(s)? This action cannot be undone.")
                }
            }
        }

        // MARK: - Views
        
        private var drawingsContent: some View {
            VStack(spacing: 0) {
                // Sort and view controls
                controlsBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                Divider()
                
                // Selection info bar
                if editMode?.wrappedValue == .active && !selectedDrawings.isEmpty {
                    selectionInfoBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Drawings grid or list
                ScrollView {
                    if viewMode == .grid {
                        drawingsGrid
                    } else {
                        drawingsList
                    }
                }
            }
        }
        
        private var controlsBar: some View {
            HStack {
                // Sort menu
                Menu {
                    Picker("Sort by", selection: $sortOrder) {
                        Label("Newest First", systemImage: "arrow.down")
                            .tag(DrawingSortOrder.dateDescending)
                        Label("Oldest First", systemImage: "arrow.up")
                            .tag(DrawingSortOrder.dateAscending)
                        Label("Name (A-Z)", systemImage: "textformat")
                            .tag(DrawingSortOrder.nameAscending)
                        Label("Name (Z-A)", systemImage: "textformat")
                            .tag(DrawingSortOrder.nameDescending)
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                        .font(.subheadline)
                }
                
                Spacer()
                
                // View mode toggle
                Picker("View Mode", selection: $viewMode) {
                    Image(systemName: "square.grid.2x2").tag(GalleryViewMode.grid)
                    Image(systemName: "list.bullet").tag(GalleryViewMode.list)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
        }
        
        private var selectionInfoBar: some View {
            HStack {
                Text("\(selectedDrawings.count) selected")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Select All") {
                    selectedDrawings = Set(lesson.drawings ?? [])
                }
                .font(.subheadline)
                
                Button("Deselect All") {
                    selectedDrawings.removeAll()
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
        }
        
        private var drawingsGrid: some View {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(sortedDrawings) { canvas in
                    DrawingThumbnailView(
                        canvas: canvas,
                        isSelected: selectedDrawings.contains(canvas),
                        isEditMode: editMode?.wrappedValue == .active,
                        onTap: {
                            if editMode?.wrappedValue == .active {
                                toggleSelection(for: canvas)
                            } else {
                                selectedCanvas = canvas
                            }
                        }
                    )
                }
            }
            .padding()
        }
        
        private var drawingsList: some View {
            LazyVStack(spacing: 0) {
                ForEach(sortedDrawings) { canvas in
                    VStack(spacing: 0) {
                        DrawingListRow(
                            canvas: canvas,
                            isSelected: selectedDrawings.contains(canvas),
                            isEditMode: editMode?.wrappedValue == .active,
                            onTap: {
                                if editMode?.wrappedValue == .active {
                                    toggleSelection(for: canvas)
                                } else {
                                    selectedCanvas = canvas
                                }
                            }
                        )
                        
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
        
        private var emptyStateView: some View {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor.opacity(0.5))
                    .symbolEffect(.pulse)
                
                VStack(spacing: 12) {
                    Text("No Drawings Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create visual notes and diagrams\nto enhance your learning")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    showingNewDrawing = true
                } label: {
                    Label("Create Your First Drawing", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
                Spacer()
            }
            .padding()
        }
        
        // MARK: - Toolbar
        
        @ToolbarContentBuilder
        private var toolbarContent: some ToolbarContent {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if editMode?.wrappedValue == .active && !selectedDrawings.isEmpty {
                    Menu {
                        Button {
                            showingExportOptions = true
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                } else {
                    Button {
                        showingNewDrawing = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        
        // MARK: - Methods
        
        private func toggleSelection(for canvas: DrawingCanvas) {
            if selectedDrawings.contains(canvas) {
                selectedDrawings.remove(canvas)
            } else {
                selectedDrawings.insert(canvas)
            }
        }
        
        private func deleteSelectedDrawings() {
            for canvas in selectedDrawings {
                modelContext.delete(canvas)
            }
            selectedDrawings.removeAll()
            editMode?.wrappedValue = .inactive
        }
        
        private func exportSelectedAsPDF() {
            // TODO: Implement PDF export
            let _ = Array(selectedDrawings)
            // Create PDF from drawings
        }
        
        private func exportSelectedAsImages() {
            // TODO: Implement image export
            let _ = Array(selectedDrawings)
            // Export as individual images
        }
    }

    /// Thumbnail view for a drawing canvas
    struct DrawingThumbnailView: View {
        // MARK: - Properties
        
        let canvas: DrawingCanvas
        let isSelected: Bool
        let isEditMode: Bool
        let onTap: () -> Void

        @State private var thumbnailImage: UIImage?

        // MARK: - Body
        
        var body: some View {
            Button(action: onTap) {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        // Thumbnail
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .aspectRatio(1, contentMode: .fit)
                            
                            if let image = thumbnailImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                        
                        // Title
                        Text(canvas.title)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        // Date
                        Text(canvas.formattedDate)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Selection indicator
                    if isEditMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                            .background(Circle().fill(Color(.systemBackground)))
                            .padding(8)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .task {
                await generateThumbnail()
            }
        }
        
        private func generateThumbnail() async {
            guard !canvas.canvasData.isEmpty,
                  let drawing = try? PKDrawing(data: canvas.canvasData) else { return }
            
            let bounds = drawing.bounds
            let scale = UIScreen.main.scale
            
            await MainActor.run {
                thumbnailImage = drawing.image(from: bounds, scale: scale)
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
            let lesson = Lesson(
                title: "Sample Lesson", 
                date: Date(),
                duration: 1800,
                transcript: "Sample transcript"
            )
            DrawingsGalleryView(lesson: lesson)
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

// MARK: - Supporting Types

enum DrawingSortOrder {
    case dateDescending
    case dateAscending
    case nameAscending
    case nameDescending
}

enum GalleryViewMode {
    case grid
    case list
}

// MARK: - Drawing List Row

struct DrawingListRow: View {
    let canvas: DrawingCanvas
    let isSelected: Bool
    let isEditMode: Bool
    let onTap: () -> Void
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator
                if isEditMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }
                
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "pencil.and.outline")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(canvas.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(canvas.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let strokeCount = canvas.strokeCount {
                            Text("• \(strokeCount) strokes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                if !isEditMode {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            await generateThumbnail()
        }
    }
    
    private func generateThumbnail() async {
        guard !canvas.canvasData.isEmpty,
              let drawing = try? PKDrawing(data: canvas.canvasData) else { return }
        
        let bounds = drawing.bounds
        let scale = UIScreen.main.scale
        
        await MainActor.run {
            thumbnailImage = drawing.image(from: bounds, scale: scale * 0.5)
        }
    }
}

// MARK: - Drawing Detail View

struct DrawingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let lesson: Lesson
    let canvas: DrawingCanvas
    
    @State private var showingEditor = false
    @State private var showingShareSheet = false
    @State private var exportedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                
                if !canvas.canvasData.isEmpty,
                   let drawing = try? PKDrawing(data: canvas.canvasData) {
                    GeometryReader { geometry in
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            Image(uiImage: drawing.image(from: drawing.bounds, scale: UIScreen.main.scale))
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: max(drawing.bounds.width, geometry.size.width),
                                    height: max(drawing.bounds.height, geometry.size.height)
                                )
                        }
                    }
                } else {
                    Text("Unable to load drawing")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(canvas.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        exportDrawing()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button("Edit") {
                        showingEditor = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showingEditor) {
                NavigationStack {
                    DrawingCanvasView(
                        lesson: lesson,
                        drawingCanvas: canvas,
                        onSave: { _ in }
                    )
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = exportedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }
    
    private func exportDrawing() {
        guard !canvas.canvasData.isEmpty,
              let drawing = try? PKDrawing(data: canvas.canvasData) else { return }
        
        exportedImage = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale * 2)
        showingShareSheet = true
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Drawing Canvas Extensions

extension DrawingCanvas {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
    
    var strokeCount: Int? {
        guard !canvasData.isEmpty,
              let drawing = try? PKDrawing(data: canvasData) else { return nil }
        return drawing.strokes.count
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        let lesson = Lesson(
            title: "Sample Lesson", 
            date: Date(),
            duration: 1800,
            transcript: "Sample transcript"
        )
        DrawingsGalleryView(lesson: lesson)
    }
    .modelContainer(PersistenceController.preview.container)
}


