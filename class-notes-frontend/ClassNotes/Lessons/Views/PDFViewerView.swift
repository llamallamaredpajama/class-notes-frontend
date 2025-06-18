import SwiftUI
import PDFKit

/// View for displaying and interacting with PDF documents
struct PDFViewerView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let lesson: Lesson
    
    @State private var pdfView = PDFView()
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var showingThumbnails = false
    @State private var showingOutline = false
    @State private var showingSearch = false
    @State private var showingShareSheet = false
    @State private var showingAnnotationTools = false
    @State private var searchText = ""
    @State private var selectedAnnotationTool: AnnotationTool = .highlight
    @State private var annotationColor: Color = .yellow
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // PDF viewer
                PDFKitView(
                    pdfView: $pdfView,
                    pdfData: lesson.pdfData,
                    currentPage: $currentPage,
                    totalPages: $totalPages
                )
                .ignoresSafeArea()
                
                // Overlay controls
                VStack {
                    Spacer()
                    
                    // Page navigation
                    if !showingAnnotationTools {
                        pageNavigationBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Annotation tools
                    if showingAnnotationTools {
                        annotationToolbar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle(lesson.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .searchable(text: $searchText, isPresented: $showingSearch, prompt: "Search in PDF")
            .onChange(of: searchText) { _, newValue in
                searchInPDF(newValue)
            }
            .sheet(isPresented: $showingThumbnails) {
                PDFThumbnailsView(pdfView: pdfView, onPageSelected: { page in
                    pdfView.go(to: page)
                    showingThumbnails = false
                })
            }
            .sheet(isPresented: $showingOutline) {
                PDFOutlineView(pdfDocument: pdfView.document, onItemSelected: { destination in
                    pdfView.go(to: destination)
                    showingOutline = false
                })
            }
            .sheet(isPresented: $showingShareSheet) {
                if let pdfData = lesson.pdfData {
                    ShareSheet(items: [pdfData])
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var pageNavigationBar: some View {
        HStack(spacing: 20) {
            // Previous page
            Button {
                if pdfView.canGoToPreviousPage {
                    pdfView.goToPreviousPage(nil)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .disabled(!pdfView.canGoToPreviousPage)
            
            // Page indicator
            VStack(spacing: 4) {
                Text("Page \(currentPage) of \(totalPages)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Page slider
                Slider(value: Binding(
                    get: { Double(currentPage) },
                    set: { value in
                        let pageNumber = Int(value)
                        if let page = pdfView.document?.page(at: pageNumber - 1) {
                            pdfView.go(to: page)
                        }
                    }
                ), in: 1...Double(totalPages), step: 1)
                    .tint(.white)
                    .frame(width: 150)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.7))
            )
            
            // Next page
            Button {
                if pdfView.canGoToNextPage {
                    pdfView.goToNextPage(nil)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .disabled(!pdfView.canGoToNextPage)
        }
        .padding()
    }
    
    private var annotationToolbar: some View {
        VStack(spacing: 16) {
            // Tool selection
            HStack(spacing: 20) {
                ForEach(AnnotationTool.allCases, id: \.self) { tool in
                    Button {
                        selectedAnnotationTool = tool
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tool.icon)
                                .font(.title2)
                            Text(tool.name)
                                .font(.caption2)
                        }
                        .foregroundColor(selectedAnnotationTool == tool ? .white : .primary)
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedAnnotationTool == tool ? Color.accentColor : Color.secondary.opacity(0.1))
                        )
                    }
                }
            }
            
            // Color picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AnnotationColor.allCases, id: \.self) { color in
                        Button {
                            annotationColor = color.color
                        } label: {
                            Circle()
                                .fill(color.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(annotationColor == color.color ? Color.primary : Color.clear, lineWidth: 3)
                                        .padding(2)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(radius: 10)
        )
        .padding()
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Done") {
                dismiss()
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                // View options
                Section("View") {
                    Button {
                        showingThumbnails = true
                    } label: {
                        Label("Thumbnails", systemImage: "square.grid.2x2")
                    }
                    
                    Button {
                        showingOutline = true
                    } label: {
                        Label("Outline", systemImage: "list.bullet.indent")
                    }
                    
                    Button {
                        showingSearch = true
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                }
                
                // Zoom options
                Section("Zoom") {
                    Button {
                        pdfView.autoScales = true
                    } label: {
                        Label("Fit to Width", systemImage: "arrow.left.and.right.square")
                    }
                    
                    Button {
                        pdfView.scaleFactor = pdfView.scaleFactor * 1.25
                    } label: {
                        Label("Zoom In", systemImage: "plus.magnifyingglass")
                    }
                    
                    Button {
                        pdfView.scaleFactor = pdfView.scaleFactor * 0.8
                    } label: {
                        Label("Zoom Out", systemImage: "minus.magnifyingglass")
                    }
                }
                
                Divider()
                
                // Actions
                Button {
                    showingAnnotationTools.toggle()
                } label: {
                    Label(showingAnnotationTools ? "Hide Tools" : "Annotate", systemImage: "pencil.tip")
                }
                
                Button {
                    printPDF()
                } label: {
                    Label("Print", systemImage: "printer")
                }
                
                Button {
                    showingShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    // MARK: - Methods
    
    private func searchInPDF(_ query: String) {
        guard !query.isEmpty else {
            pdfView.clearSelection()
            return
        }
        
        if let matches = pdfView.document?.findString(query, withOptions: [.caseInsensitive]),
           let firstMatch = matches.first {
            pdfView.go(to: firstMatch)
            pdfView.setCurrentSelection(firstMatch, animate: true)
        }
    }
    
    private func printPDF() {
        guard let pdfDocument = pdfView.document else { return }
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = lesson.title
        printInfo.outputType = .general
        
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printingItem = pdfDocument.dataRepresentation()
        
        printController.present(animated: true)
    }
}

// MARK: - PDFKit Wrapper

struct PDFKitView: UIViewRepresentable {
    @Binding var pdfView: PDFView
    let pdfData: Data?
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    
    func makeUIView(context: Context) -> PDFView {
        pdfView.delegate = context.coordinator
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true, withViewOptions: nil)
        
        if let data = pdfData {
            pdfView.document = PDFDocument(data: data)
            totalPages = pdfView.document?.pageCount ?? 1
        }
        
        // Enable annotations
        pdfView.isInMarkupMode = true
        
        // Add page change observer
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let data = pdfData, uiView.document == nil {
            uiView.document = PDFDocument(data: data)
            totalPages = uiView.document?.pageCount ?? 1
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        let parent: PDFKitView
        
        init(_ parent: PDFKitView) {
            self.parent = parent
        }
        
        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }
            
            parent.currentPage = pageIndex + 1
        }
    }
}

// MARK: - Supporting Types

enum AnnotationTool: String, CaseIterable {
    case highlight = "Highlight"
    case underline = "Underline"
    case strikethrough = "Strike"
    case pen = "Pen"
    case text = "Text"
    case note = "Note"
    
    var name: String { rawValue }
    
    var icon: String {
        switch self {
        case .highlight: return "highlighter"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .pen: return "pencil.tip"
        case .text: return "textformat"
        case .note: return "note.text"
        }
    }
}

enum AnnotationColor: CaseIterable {
    case yellow
    case green
    case blue
    case pink
    case orange
    case purple
    
    var color: Color {
        switch self {
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .pink: return .pink
        case .orange: return .orange
        case .purple: return .purple
        }
    }
}

// MARK: - PDF Thumbnails View

struct PDFThumbnailsView: View {
    let pdfView: PDFView
    let onPageSelected: (PDFPage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let document = pdfView.document {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0..<document.pageCount, id: \.self) { index in
                            if let page = document.page(at: index) {
                                PDFThumbnailView(
                                    page: page,
                                    pageNumber: index + 1,
                                    isCurrentPage: page == pdfView.currentPage
                                ) {
                                    onPageSelected(page)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Pages")
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

struct PDFThumbnailView: View {
    let page: PDFPage
    let pageNumber: Int
    let isCurrentPage: Bool
    let action: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .background(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isCurrentPage ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(0.77, contentMode: .fit)
                        .overlay(
                            ProgressView()
                        )
                }
                
                Text("Page \(pageNumber)")
                    .font(.caption)
                    .foregroundColor(isCurrentPage ? .accentColor : .secondary)
            }
        }
        .task {
            await generateThumbnail()
        }
    }
    
    private func generateThumbnail() async {
        let size = CGSize(width: 100, height: 130)
        let thumbnail = page.thumbnail(of: size, for: .mediaBox)
        
        await MainActor.run {
            self.thumbnail = thumbnail
        }
    }
}

// MARK: - PDF Outline View

struct PDFOutlineView: View {
    let pdfDocument: PDFDocument?
    let onItemSelected: (PDFDestination) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if let outline = pdfDocument?.outlineRoot {
                    OutlineSection(outline: outline, onItemSelected: onItemSelected)
                } else {
                    Text("No outline available")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("Outline")
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

struct OutlineSection: View {
    let outline: PDFOutline
    let onItemSelected: (PDFDestination) -> Void
    
    var body: some View {
        ForEach(0..<outline.numberOfChildren, id: \.self) { index in
            if let child = outline.child(at: index) {
                if child.numberOfChildren > 0 {
                    DisclosureGroup {
                        OutlineSection(outline: child, onItemSelected: onItemSelected)
                    } label: {
                        Text(child.label ?? "")
                    }
                } else {
                    Button {
                        if let destination = child.destination {
                            onItemSelected(destination)
                        }
                    } label: {
                        Text(child.label ?? "")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Lesson Extension

extension Lesson {
    var pdfData: Data? {
        // TODO: Implement PDF data storage
        // For now, return sample PDF data
        return nil
    }
}

// MARK: - Preview

#Preview {
    let lesson = Lesson(
        title: "Sample PDF Document",
        date: Date(),
        duration: 0,
        transcript: ""
    )
    return PDFViewerView(lesson: lesson)
} 