import SwiftUI
import SwiftData

/// View for managing and organizing all documents and PDFs
struct LibraryView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Lesson.createdAt, order: .reverse) private var lessons: [Lesson]
    
    @State private var searchText = ""
    @State private var selectedFilter: DocumentFilter = .all
    @State private var showingImportDocument = false
    @State private var sortOrder: SortOrder = .dateDescending
    
    private var filteredLessons: [Lesson] {
        lessons.filter { lesson in
            let matchesFilter: Bool = {
                switch selectedFilter {
                case .all:
                    return true
                case .pdfs:
                    return lesson.hasPDF
                case .transcripts:
                    return !lesson.transcript.isEmpty
                case .drawings:
                    return !(lesson.drawings?.isEmpty ?? true)
                case .scanned:
                    return !(lesson.scannedDocuments?.isEmpty ?? true)
                }
            }()
            
            guard matchesFilter else { return false }
            
            if searchText.isEmpty {
                return true
            }
            
            return lesson.title.localizedCaseInsensitiveContains(searchText) ||
                   lesson.transcript.localizedCaseInsensitiveContains(searchText) ||
                   lesson.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }.sorted { first, second in
            switch sortOrder {
            case .dateDescending:
                return first.createdAt > second.createdAt
            case .dateAscending:
                return first.createdAt < second.createdAt
            case .nameAscending:
                return first.title < second.title
            case .nameDescending:
                return first.title > second.title
            case .sizeDescending:
                return (first.fileSize ?? 0) > (second.fileSize ?? 0)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if lessons.isEmpty {
                    emptyStateView
                } else {
                    documentsList
                }
            }
            .navigationTitle("Library")
            .toolbar {
                toolbarContent
            }
            .searchable(text: $searchText, prompt: "Search documents")
            .sheet(isPresented: $showingImportDocument) {
                DocumentImportView()
            }
        }
    }
    
    // MARK: - Views
    
    private var documentsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                filterChips
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                if filteredLessons.isEmpty {
                    noResultsView
                } else {
                    ForEach(filteredLessons) { lesson in
                        NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                            DocumentRowView(lesson: lesson)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .padding(.leading)
                    }
                }
            }
        }
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DocumentFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Your Library is Empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Import documents or create lessons to build your library")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showingImportDocument = true
            } label: {
                Label("Import Document", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No documents found")
                .font(.headline)
            
            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Picker("Sort by", selection: $sortOrder) {
                    Label("Newest First", systemImage: "arrow.down")
                        .tag(SortOrder.dateDescending)
                    Label("Oldest First", systemImage: "arrow.up")
                        .tag(SortOrder.dateAscending)
                    Label("Name (A-Z)", systemImage: "textformat")
                        .tag(SortOrder.nameAscending)
                    Label("Name (Z-A)", systemImage: "textformat")
                        .tag(SortOrder.nameDescending)
                    Label("Largest First", systemImage: "doc.badge.arrow.up")
                        .tag(SortOrder.sizeDescending)
                }
                
                Divider()
                
                Button {
                    showingImportDocument = true
                } label: {
                    Label("Import Document", systemImage: "square.and.arrow.down")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

// MARK: - Supporting Types

enum DocumentFilter: String, CaseIterable {
    case all = "All"
    case pdfs = "PDFs"
    case transcripts = "Transcripts"
    case drawings = "Drawings"
    case scanned = "Scanned"
    
    var title: String { rawValue }
}

enum SortOrder {
    case dateDescending
    case dateAscending
    case nameAscending
    case nameDescending
    case sizeDescending
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DocumentRowView: View {
    let lesson: Lesson
    
    var body: some View {
        HStack(spacing: 12) {
            // Document icon
            Image(systemName: documentIcon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(10)
            
            // Document info
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let course = lesson.course {
                        Text(course.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(lesson.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let size = lesson.fileSize {
                        Text("• \(formatFileSize(size))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Status indicators
            HStack(spacing: 4) {
                if lesson.hasPDF {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .contentShape(Rectangle())
    }
    
    private var documentIcon: String {
        if lesson.hasPDF {
            return "doc.fill"
        } else if !(lesson.drawings?.isEmpty ?? true) {
            return "pencil.and.outline"
        } else if !(lesson.scannedDocuments?.isEmpty ?? true) {
            return "doc.text.image"
        } else {
            return "doc.text"
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Document Import View

struct DocumentImportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Import Documents")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select a document to import into your library")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    // TODO: Implement document picker
                } label: {
                    Label("Choose File", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .modelContainer(PersistenceController.preview.container)
} 