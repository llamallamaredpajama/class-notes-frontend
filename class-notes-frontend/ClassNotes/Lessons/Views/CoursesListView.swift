import SwiftUI
import SwiftData

/// Main view for displaying the list of courses
struct CoursesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name) private var courses: [Course]
    
    @State private var showingAddCourse = false
    @State private var searchText = ""
    
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
    
    private func deleteCourses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(courses[index])
        }
    }
}

/// View shown when there are no courses
struct EmptyCoursesView: View {
    @Binding var showingAddCourse: Bool
    
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
    let course: Course
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: course.color) ?? .blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(course.name.prefix(2).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                
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
            
            Spacer()
            
            if course.isActive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Placeholder for course detail view
struct CourseDetailView: View {
    let course: Course
    
    var body: some View {
        Text("Course Detail: \(course.name)")
            .navigationTitle(course.name)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CoursesListView()
        .modelContainer(PersistenceController.preview.container)
} 