// 1. Standard library
import SwiftUI

/// Main tab view for authenticated users
struct MainTabView: View {
    // MARK: - Body
    var body: some View {
        TabView {
            LessonsListView()
                .tabItem {
                    Label("Lessons", systemImage: "book.fill")
                }

            CoursesListView()
                .tabItem {
                    Label("Courses", systemImage: "folder.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
