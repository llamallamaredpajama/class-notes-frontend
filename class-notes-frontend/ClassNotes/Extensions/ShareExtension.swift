import SwiftUI
import UniformTypeIdentifiers

/// Share Extension for importing documents into Class Notes
struct ShareExtension: View {
    // MARK: - Properties
    
    @State private var importedItems: [ImportedItem] = []
    @State private var isProcessing = false
    @State private var selectedLesson: Lesson?
    @State private var showingLessonPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let extensionContext: NSExtensionContext
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if isProcessing {
                    processingView
                } else if importedItems.isEmpty {
                    loadingView
                } else {
                    importView
                }
            }
            .navigationTitle("Import to Class Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingLessonPicker) {
                LessonPickerView(selectedLesson: $selectedLesson)
            }
            .alert("Import Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadItems()
            }
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading items...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Importing to Class Notes...")
                .font(.headline)
            
            Text("This may take a moment")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var importView: some View {
        List {
            // Import destination
            Section {
                HStack {
                    Label("Import to", systemImage: "folder")
                    
                    Spacer()
                    
                    if let lesson = selectedLesson {
                        Text(lesson.title)
                            .foregroundColor(.secondary)
                    } else {
                        Text("New Lesson")
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingLessonPicker = true
                }
            } header: {
                Text("Destination")
            } footer: {
                Text("Choose an existing lesson or create a new one")
            }
            
            // Items to import
            Section {
                ForEach(importedItems) { item in
                    ImportedItemRow(item: item)
                }
            } header: {
                Text("Items to Import (\(importedItems.count))")
            }
            
            // Import options
            if importedItems.contains(where: { $0.type == .image }) {
                Section {
                    Toggle("Convert images to PDF", isOn: .constant(true))
                    Toggle("Apply OCR to images", isOn: .constant(true))
                } header: {
                    Text("Import Options")
                }
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                extensionContext.completeRequest(returningItems: nil)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Import") {
                performImport()
            }
            .fontWeight(.semibold)
            .disabled(isProcessing || importedItems.isEmpty)
        }
    }
    
    // MARK: - Methods
    
    private func loadItems() async {
        guard let inputItems = extensionContext.inputItems as? [NSExtensionItem] else { return }
        
        var items: [ImportedItem] = []
        
        for extensionItem in inputItems {
            guard let attachments = extensionItem.attachments else { continue }
            
            for provider in attachments {
                if let item = await loadItem(from: provider) {
                    items.append(item)
                }
            }
        }
        
        await MainActor.run {
            importedItems = items
        }
    }
    
    private func loadItem(from provider: NSItemProvider) async -> ImportedItem? {
        // Check for supported types
        let typeIdentifiers = [
            UTType.pdf,
            UTType.image,
            UTType.text,
            UTType.audio,
            UTType.movie
        ]
        
        for type in typeIdentifiers {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                do {
                    let url = try await provider.loadItem(forTypeIdentifier: type.identifier) as? URL
                    if let url = url {
                        return ImportedItem(url: url, type: ImportedItemType(from: type))
                    }
                } catch {
                    print("Failed to load item: \(error)")
                }
            }
        }
        
        return nil
    }
    
    private func performImport() {
        isProcessing = true
        
        Task {
            do {
                // Create or get lesson
                let lesson = selectedLesson ?? createNewLesson()
                
                // Import each item
                for item in importedItems {
                    try await importItem(item, to: lesson)
                }
                
                // Complete the extension
                await MainActor.run {
                    extensionContext.completeRequest(returningItems: nil)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func createNewLesson() -> Lesson {
        let lesson = Lesson(title: "Imported \(Date().formatted())")
        // TODO: Save to Core Data
        return lesson
    }
    
    private func importItem(_ item: ImportedItem, to lesson: Lesson) async throws {
        switch item.type {
        case .pdf:
            // Import PDF
            _ = try Data(contentsOf: item.url)
            // TODO: Save PDF to lesson
            
        case .image:
            // Import image
            if UIImage(contentsOfFile: item.url.path) != nil {
                // TODO: Convert to PDF or save as drawing
            }
            
        case .text:
            // Import text
            _ = try String(contentsOf: item.url, encoding: .utf8)
            // TODO: Add to lesson notes
            
        case .audio:
            // Import audio
            _ = try Data(contentsOf: item.url)
            // TODO: Save audio to lesson
            
        case .video:
            // Extract audio from video
            // TODO: Process video
            break
        }
    }
}

// MARK: - Supporting Types

struct ImportedItem: Identifiable {
    let id = UUID()
    let url: URL
    let type: ImportedItemType
    
    var name: String {
        url.lastPathComponent
    }
    
    var size: String {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let bytes = attributes?[.size] as? Int64 ?? 0
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

enum ImportedItemType {
    case pdf
    case image
    case text
    case audio
    case video
    
    init(from utType: UTType) {
        switch utType {
        case .pdf:
            self = .pdf
        case .image:
            self = .image
        case .text:
            self = .text
        case .audio:
            self = .audio
        case .movie:
            self = .video
        default:
            self = .text
        }
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        case .text: return "doc.text.fill"
        case .audio: return "waveform"
        case .video: return "video.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pdf: return .red
        case .image: return .green
        case .text: return .blue
        case .audio: return .purple
        case .video: return .orange
        }
    }
}

// MARK: - Imported Item Row

struct ImportedItemRow: View {
    let item: ImportedItem
    
    var body: some View {
        HStack {
            Image(systemName: item.type.icon)
                .font(.title2)
                .foregroundColor(item.type.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(item.size)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Lesson Picker View

struct LessonPickerView: View {
    @Binding var selectedLesson: Lesson?
    @Environment(\.dismiss) private var dismiss
    @State private var lessons: [Lesson] = []
    
    var body: some View {
        NavigationStack {
            List {
                // Create new option
                Section {
                    Button {
                        selectedLesson = nil
                        dismiss()
                    } label: {
                        Label("Create New Lesson", systemImage: "plus.circle")
                            .foregroundColor(.accentColor)
                    }
                }
                
                // Existing lessons
                Section {
                    ForEach(lessons) { lesson in
                        Button {
                            selectedLesson = lesson
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(lesson.title)
                                        .foregroundColor(.primary)
                                    
                                    if let course = lesson.course {
                                        Text(course.name)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedLesson?.id == lesson.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    }
                } header: {
                    Text("Recent Lessons")
                }
            }
            .navigationTitle("Choose Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                // TODO: Load recent lessons
                lessons = []
            }
        }
    }
} 