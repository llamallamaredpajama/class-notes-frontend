import SwiftUI
import SwiftData

/// Main view for displaying the list of lessons
struct LessonsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Lesson.createdAt, order: .reverse) private var lessons: [Lesson]
    
    @StateObject private var viewModel = LessonListViewModel(lessonService: MockLessonService())
    @State private var showingAddLesson = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if lessons.isEmpty {
                    EmptyLessonsView(showingAddLesson: $showingAddLesson)
                } else {
                    lessonsList
                }
            }
            .navigationTitle("Lessons")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddLesson = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search lessons")
            .sheet(isPresented: $showingAddLesson) {
                // TODO: Add lesson creation view
                Text("Add Lesson View")
            }
        }
    }
    
    private var lessonsList: some View {
        List {
            ForEach(filteredLessons) { lesson in
                NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                    LessonRowView(lesson: lesson)
                }
            }
            .onDelete(perform: deleteLessons)
        }
    }
    
    private var filteredLessons: [Lesson] {
        if searchText.isEmpty {
            return lessons
        } else {
            return lessons.filter { lesson in
                lesson.title.localizedCaseInsensitiveContains(searchText) ||
                lesson.transcript.localizedCaseInsensitiveContains(searchText) ||
                lesson.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    private func deleteLessons(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(lessons[index])
        }
    }
}

/// View shown when there are no lessons
struct EmptyLessonsView: View {
    @Binding var showingAddLesson: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Lessons Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start by creating your first lesson")
                .foregroundColor(.secondary)
            
            Button {
                showingAddLesson = true
            } label: {
                Label("Create Lesson", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

/// Row view for displaying a lesson in the list
struct LessonRowView: View {
    let lesson: Lesson
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
            
            HStack {
                if let course = lesson.course {
                    Text(course.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(lesson.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if lesson.hasAudio {
                    Image(systemName: "mic.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if lesson.hasPDF {
                    Image(systemName: "doc.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !lesson.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(lesson.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            if lesson.progress > 0 {
                ProgressView(value: lesson.progress)
                    .tint(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LessonsListView()
        .modelContainer(PersistenceController.preview.container)
} 