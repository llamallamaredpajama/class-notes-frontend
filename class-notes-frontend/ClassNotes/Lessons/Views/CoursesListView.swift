import SwiftUI
import SwiftData

/// Main view for displaying the list of courses
struct CoursesListView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name) private var courses: [Course]
    
    @State private var showingAddCourse = false
    @State private var searchText = ""
    
    private var filteredCourses: [Course] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) ||
                (course.courseCode?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (course.instructor?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if courses.isEmpty {
                    EmptyCoursesView(showingAddCourse: $showingAddCourse)
                } else {
                    coursesList
                }
            }
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCourse = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search courses")
            .sheet(isPresented: $showingAddCourse) {
                // TODO: Add course creation view
                Text("Add Course View")
            }
        }
    }
    
    // MARK: - Views
    
    private var coursesList: some View {
        List {
            ForEach(filteredCourses) { course in
                NavigationLink(destination: CourseDetailView(course: course)) {
                    CourseRowView(course: course)
                }
            }
            .onDelete(perform: deleteCourses)
        }
    }
    
    // MARK: - Methods
    
    private func deleteCourses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(courses[index])
        }
    }
}

// MARK: - Supporting Views

/// View shown when there are no courses
struct EmptyCoursesView: View {
    // MARK: - Properties
    
    @Binding var showingAddCourse: Bool
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Courses Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start by creating your first course")
                .foregroundColor(.secondary)
            
            Button {
                showingAddCourse = true
            } label: {
                Label("Create Course", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

/// Row view for displaying a course in the list
struct CourseRowView: View {
    // MARK: - Properties
    
    let course: Course
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            courseIcon
            courseDetails
            Spacer()
            
            if course.isActive {
                activeIndicator
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Views
    
    private var courseIcon: some View {
        Circle()
            .fill(Color(hex: course.color) ?? .blue)
            .frame(width: 40, height: 40)
            .overlay(
                Text(course.name.prefix(2).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    private var courseDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(course.name)
                .font(.headline)
            
            courseMetadata
            courseStats
        }
    }
    
    private var courseMetadata: some View {
        HStack {
            if let courseCode = course.courseCode {
                Text(courseCode)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let instructor = course.instructor {
                Text("• \(instructor)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var courseStats: some View {
        HStack {
            Image(systemName: "book.closed")
                .font(.caption2)
            Text("\(course.lessonCount) lessons")
                .font(.caption)
            
            Spacer()
            
            Text(course.formattedProgress)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var activeIndicator: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 8, height: 8)
    }
}

/// Placeholder for course detail view
struct CourseDetailView: View {
    // MARK: - Properties
    
    let course: Course
    
    // MARK: - Body
    
    var body: some View {
        Text("Course Detail: \(course.name)")
            .navigationTitle(course.name)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    CoursesListView()
        .modelContainer(PersistenceController.preview.container)
} 