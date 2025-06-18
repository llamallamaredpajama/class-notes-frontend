// 1. Standard library
import SwiftUI

/// Main tab view for authenticated users
struct MainTabView: View {
    // MARK: - Properties
    @State private var selectedTab = 0
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            LessonsListView()
                .tabItem {
                    Label("Lessons", systemImage: "mic.fill")
                }
                .tag(0)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel(authService: MockAuthenticationService()))
}
