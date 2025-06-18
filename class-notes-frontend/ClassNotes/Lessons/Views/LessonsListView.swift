import SwiftUI
import SwiftData

/// Main view for displaying the list of lessons
struct LessonsListView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Lesson.createdAt, order: .reverse) private var lessons: [Lesson]
    
    @StateObject private var viewModel = LessonListViewModel(lessonService: MockLessonService())
    @State private var showingAddLesson = false
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list
    @State private var sortOrder: LessonSortOrder = .dateDescending
    @State private var isLoading = false
    
    private var sortedLessons: [Lesson] {
        let filtered = searchText.isEmpty ? lessons : lessons.filter { lesson in
            lesson.title.localizedCaseInsensitiveContains(searchText) ||
            lesson.transcript.localizedCaseInsensitiveContains(searchText) ||
            lesson.tags.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
            (lesson.course?.name.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        return filtered.sorted { first, second in
            switch sortOrder {
            case .dateDescending:
                return first.createdAt > second.createdAt
            case .dateAscending:
                return first.createdAt < second.createdAt
            case .titleAscending:
                return first.title < second.title
            case .titleDescending:
                return first.title > second.title
            case .durationDescending:
                return first.duration > second.duration
            case .durationAscending:
                return first.duration < second.duration
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading && lessons.isEmpty {
                    LoadingSkeletonView()
                } else if lessons.isEmpty && !isLoading {
                    EmptyLessonsView(showingAddLesson: $showingAddLesson)
                } else {
                    ZStack {
                        if viewMode == .list {
                            lessonsList
                        } else {
                            lessonsGrid
                        }
                        
                        // Floating action button
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                FloatingActionButton {
                                    showingAddLesson = true
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Lessons")
            .toolbar {
                toolbarContent
            }
            .searchable(text: $searchText, prompt: "Search lessons, courses, or tags")
            .sheet(isPresented: $showingAddLesson) {
                NewLessonView()
            }
            .refreshable {
                await refreshLessons()
            }
            .task {
                if lessons.isEmpty {
                    await loadInitialLessons()
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var lessonsList: some View {
        List {
            ForEach(sortedLessons) { lesson in
                NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                    LessonRowView(lesson: lesson)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteLesson(lesson)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        shareLesson(lesson)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        toggleFavorite(lesson)
                    } label: {
                        Label(lesson.isFavorite ? "Unfavorite" : "Favorite", 
                              systemImage: lesson.isFavorite ? "star.fill" : "star")
                    }
                    .tint(.yellow)
                }
            }
            .onDelete(perform: deleteLessons)
        }
        .listStyle(.plain)
    }
    
    private var lessonsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(sortedLessons) { lesson in
                    NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                        LessonGridItemView(lesson: lesson)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button {
                            toggleFavorite(lesson)
                        } label: {
                            Label(lesson.isFavorite ? "Unfavorite" : "Favorite",
                                  systemImage: lesson.isFavorite ? "star.fill" : "star")
                        }
                        
                        Button {
                            shareLesson(lesson)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            deleteLesson(lesson)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Picker("Sort by", selection: $sortOrder) {
                    Label("Newest First", systemImage: "clock.arrow.circlepath")
                        .tag(LessonSortOrder.dateDescending)
                    Label("Oldest First", systemImage: "clock.arrow.circlepath")
                        .tag(LessonSortOrder.dateAscending)
                    Label("Title (A-Z)", systemImage: "textformat")
                        .tag(LessonSortOrder.titleAscending)
                    Label("Title (Z-A)", systemImage: "textformat")
                        .tag(LessonSortOrder.titleDescending)
                    Label("Longest First", systemImage: "timer")
                        .tag(LessonSortOrder.durationDescending)
                    Label("Shortest First", systemImage: "timer")
                        .tag(LessonSortOrder.durationAscending)
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewMode = viewMode == .list ? .grid : .list
                    }
                } label: {
                    Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                }
                
                if lessons.isEmpty {
                    Button {
                        showingAddLesson = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadInitialLessons() async {
        isLoading = true
        // Simulate loading
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }
    
    private func refreshLessons() async {
        // TODO: Implement actual refresh from backend
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func deleteLessons(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedLessons[index])
        }
    }
    
    private func deleteLesson(_ lesson: Lesson) {
        withAnimation {
            modelContext.delete(lesson)
        }
    }
    
    private func toggleFavorite(_ lesson: Lesson) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            lesson.isFavorite.toggle()
            try? modelContext.save()
        }
    }
    
    private func shareLesson(_ lesson: Lesson) {
        // TODO: Implement sharing
    }
}

// MARK: - Supporting Types

enum ViewMode {
    case list
    case grid
}

enum LessonSortOrder {
    case dateDescending
    case dateAscending
    case titleAscending
    case titleDescending
    case durationDescending
    case durationAscending
}

// MARK: - Supporting Views

/// Empty state view with illustration
struct EmptyLessonsView: View {
    @Binding var showingAddLesson: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 0) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor.opacity(0.7))
                        .offset(y: -10)
                }
            }
            
            VStack(spacing: 12) {
                Text("Ready to Start Learning?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Record your first lesson and let\nClass Notes help you study smarter")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddLesson = true
            } label: {
                Label("Create Your First Lesson", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

/// Enhanced row view with swipe actions preview
struct LessonRowView: View {
    let lesson: Lesson
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with title and favorite indicator
            HStack {
                Text(lesson.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if lesson.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            // Metadata row
            HStack(spacing: 12) {
                if let course = lesson.course {
                    Label(course.name, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Label(lesson.formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if lesson.duration > 0 {
                    Label(formatDuration(TimeInterval(lesson.duration)), systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Status indicators
            HStack(spacing: 16) {
                if lesson.hasAudio {
                    StatusIndicator(
                        icon: "mic.fill",
                        label: "Audio",
                        color: .blue
                    )
                }
                
                if !lesson.transcript.isEmpty {
                    StatusIndicator(
                        icon: "text.alignleft",
                        label: "Transcript",
                        color: .green
                    )
                }
                
                if lesson.hasPDF {
                    StatusIndicator(
                        icon: "doc.fill",
                        label: "PDF",
                        color: .orange
                    )
                }
                
                if lesson.processingStatus == .processing {
                    StatusIndicator(
                        icon: "arrow.triangle.2.circlepath",
                        label: "Processing",
                        color: .purple,
                        isAnimating: true
                    )
                }
            }
            
            // Tags
            if !lesson.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(lesson.tags, id: \.self) { tag in
                            TagChip(text: tag)
                        }
                    }
                }
            }
            
            // Progress bar if available
            if lesson.progress > 0 && lesson.progress < 1 {
                ProgressView(value: lesson.progress)
                    .tint(.accentColor)
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: seconds) ?? ""
    }
}

/// Grid item view for lessons
struct LessonGridItemView: View {
    let lesson: Lesson
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail area
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .aspectRatio(16/9, contentMode: .fit)
                
                if lesson.processingStatus == .processing {
                    ProgressView()
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: lesson.hasPDF ? "doc.fill" : "mic.fill")
                        .font(.largeTitle)
                        .foregroundColor(.accentColor.opacity(0.5))
                }
                
                // Favorite indicator
                if lesson.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.3)))
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                if let course = lesson.course {
                    Text(course.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text(lesson.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        if lesson.hasAudio {
                            Image(systemName: "mic.fill")
                                .font(.caption2)
                        }
                        if lesson.hasPDF {
                            Image(systemName: "doc.fill")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.15) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

/// Status indicator component
struct StatusIndicator: View {
    let icon: String
    let label: String
    let color: Color
    var isAnimating: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .rotationEffect(isAnimating ? .degrees(360) : .degrees(0))
                .animation(
                    isAnimating ? 
                    Animation.linear(duration: 1).repeatForever(autoreverses: false) : 
                    .default,
                    value: isAnimating
                )
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

/// Tag chip component
struct TagChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.1))
            )
            .foregroundColor(.accentColor)
    }
}

/// Loading skeleton view
struct LoadingSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonRow()
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

struct SkeletonRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
                .frame(maxWidth: .infinity)
            
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 16)
            }
            
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 14)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1).repeatForever(), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

/// Floating action button
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("List View") {
    LessonsListView()
        .modelContainer(PersistenceController.preview.container)
}

#Preview("Grid View") {
    LessonsListView()
        .modelContainer(PersistenceController.preview.container)
} 