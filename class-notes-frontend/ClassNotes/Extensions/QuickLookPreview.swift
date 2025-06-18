import SwiftUI
import QuickLook
import PDFKit
import PencilKit

/// Quick Look preview controller for Class Notes documents
class ClassNotesPreviewController: QLPreviewController {
    private var previewItems: [ClassNotesPreviewItem] = []
    
    init(lesson: Lesson) {
        super.init(nibName: nil, bundle: nil)
        setupPreviewItems(for: lesson)
        dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPreviewItems(for lesson: Lesson) {
        // Add PDF if available
        if let pdfURL = lesson.pdfURL,
           let pdfData = try? Data(contentsOf: pdfURL) {
            let pdfItem = ClassNotesPreviewItem(
                title: "\(lesson.title) - PDF",
                data: pdfData,
                type: .pdf
            )
            previewItems.append(pdfItem)
        }
        
        // Add transcript
        if !lesson.transcript.isEmpty {
            let transcriptData = lesson.transcript.data(using: .utf8) ?? Data()
            let transcriptItem = ClassNotesPreviewItem(
                title: "\(lesson.title) - Transcript",
                data: transcriptData,
                type: .text
            )
            previewItems.append(transcriptItem)
        }
        
        // Add drawings as images
        if let drawings = lesson.drawings {
            for (index, drawing) in drawings.enumerated() {
                let drawingData = drawing.canvasData
                if let pkDrawing = try? PKDrawing(data: drawingData) {
                    let image = pkDrawing.image(from: pkDrawing.bounds, scale: 2.0)
                    if let imageData = image.pngData() {
                        let drawingItem = ClassNotesPreviewItem(
                            title: "\(lesson.title) - Drawing \(index + 1)",
                            data: imageData,
                            type: .image
                        )
                        previewItems.append(drawingItem)
                    }
                }
            }
        }
    }
}

// MARK: - QLPreviewControllerDataSource

extension ClassNotesPreviewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return previewItems.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewItems[index]
    }
}

// MARK: - Preview Item

class ClassNotesPreviewItem: NSObject, QLPreviewItem {
    let title: String
    let data: Data
    let type: PreviewType
    private let fileURL: URL
    
    enum PreviewType {
        case pdf
        case text
        case image
        
        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .text: return "txt"
            case .image: return "png"
            }
        }
    }
    
    init(title: String, data: Data, type: PreviewType) {
        self.title = title
        self.data = data
        self.type = type
        
        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString).\(type.fileExtension)"
        self.fileURL = tempDir.appendingPathComponent(fileName)
        
        super.init()
        
        // Write data to temporary file
        try? data.write(to: fileURL)
    }
    
    deinit {
        // Clean up temporary file
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - QLPreviewItem
    
    var previewItemURL: URL? {
        return fileURL
    }
    
    var previewItemTitle: String? {
        return title
    }
}

// MARK: - SwiftUI Preview View

struct QuickLookPreview: UIViewControllerRepresentable {
    let lesson: Lesson
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let previewController = ClassNotesPreviewController(lesson: lesson)
        previewController.delegate = context.coordinator
        
        let navigationController = UINavigationController(rootViewController: previewController)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDelegate {
        let parent: QuickLookPreview
        
        init(_ parent: QuickLookPreview) {
            self.parent = parent
        }
        
        func previewControllerWillDismiss(_ controller: QLPreviewController) {
            parent.isPresented = false
        }
    }
}

// MARK: - File Provider Preview

struct FileProviderPreview: View {
    let fileURL: URL
    @State private var lesson: Lesson?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let lesson = lesson {
                    LessonPreviewView(lesson: lesson)
                } else if let error = error {
                    ErrorView(error: error)
                } else {
                    Text("Unable to load file")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Class Notes Preview")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadLesson()
            }
        }
    }
    
    private func loadLesson() async {
        do {
            _ = try Data(contentsOf: fileURL)
            // TODO: Implement proper lesson loading from file
            // For now, create a mock lesson
            lesson = Lesson(title: "Sample Lesson", transcript: "Sample transcript content")
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
}

// MARK: - Lesson Preview View

struct LessonPreviewView: View {
    let lesson: Lesson
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Summary tab
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !lesson.summary.isEmpty {
                        Text("Summary")
                            .font(.headline)
                        
                        Text(lesson.summary)
                            .font(.body)
                    } else {
                        Text("No summary available")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .tabItem {
                Label("Summary", systemImage: "doc.text")
            }
            .tag(0)
            
            // Transcript tab
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !lesson.transcript.isEmpty {
                        Text("Transcript")
                            .font(.headline)
                        
                        Text(lesson.transcript)
                            .font(.body)
                    } else {
                        Text("No transcript available")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .tabItem {
                Label("Transcript", systemImage: "text.quote")
            }
            .tag(1)
            
            // Details tab
            Form {
                Section {
                    LabeledContent("Title", value: lesson.title)
                    
                    if let course = lesson.course {
                        LabeledContent("Course", value: course.name)
                    }
                    
                    LabeledContent("Created", value: lesson.createdAt.formatted())
                    
                    if lesson.duration > 0 {
                        LabeledContent("Duration", value: formatDuration(TimeInterval(lesson.duration)))
                    }
                } header: {
                    Text("Lesson Information")
                }
                
                Section("Content") {
                    if lesson.hasAudio {
                        Label("Audio Recording", systemImage: "waveform")
                    }
                    
                    if lesson.hasDrawings {
                        Label("\(lesson.drawings?.count ?? 0) Drawings", systemImage: "pencil.and.outline")
                    }
                    
                    if lesson.hasDocuments {
                        Label("Scanned Documents", systemImage: "doc.text.viewfinder")
                    }
                    
                    if lesson.hasPDF {
                        Label("PDF Available", systemImage: "doc.fill")
                    }
                }
            }
            .tabItem {
                Label("Details", systemImage: "info.circle")
            }
            .tag(2)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

// MARK: - Thumbnail Provider

class ClassNotesThumbnailProvider {
    static func generateThumbnail(for lesson: Lesson, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Icon
            let iconSize: CGFloat = min(size.width, size.height) * 0.4
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: size.height * 0.2,
                width: iconSize,
                height: iconSize
            )
            
            let icon = UIImage(systemName: "graduationcap.fill")
            icon?.withTintColor(.systemBlue).draw(in: iconRect)
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.label
            ]
            
            let title = lesson.title as NSString
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: size.height * 0.7,
                width: titleSize.width,
                height: titleSize.height
            )
            
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Course name
            if let course = lesson.course {
                let courseAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                
                let courseName = course.name as NSString
                let courseSize = courseName.size(withAttributes: courseAttributes)
                let courseRect = CGRect(
                    x: (size.width - courseSize.width) / 2,
                    y: titleRect.maxY + 4,
                    width: courseSize.width,
                    height: courseSize.height
                )
                
                courseName.draw(in: courseRect, withAttributes: courseAttributes)
            }
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Error Loading File")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Lesson Extensions

extension Lesson {
    var hasDrawings: Bool {
        !(drawings ?? []).isEmpty
    }
    
    var hasDocuments: Bool {
        !(scannedDocuments ?? []).isEmpty
    }
}

// MARK: - Preview

#Preview {
    FileProviderPreview(
        fileURL: URL(fileURLWithPath: "/tmp/sample.classnotes")
    )
} 