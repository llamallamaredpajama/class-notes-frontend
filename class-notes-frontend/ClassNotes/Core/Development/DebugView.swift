#if DEBUG
import SwiftUI
import SwiftData
import UIKit

/// Main debug view for testing components and flows without Xcode
struct DebugView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Current development focus
            CurrentDevelopmentView()
                .tabItem {
                    Label("Current", systemImage: "hammer")
                }
                .tag(0)
            
            // Test authentication flows
            AuthenticationDebugView()
                .tabItem {
                    Label("Auth", systemImage: "person.circle")
                }
                .tag(1)
            
            // Component gallery
            ComponentGalleryView()
                .tabItem {
                    Label("Components", systemImage: "square.grid.2x2")
                }
                .tag(2)
            
            // Settings and utilities
            DebugSettingsView()
                .tabItem {
                    Label("Debug", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

// MARK: - Current Development View
struct CurrentDevelopmentView: View {
    var body: some View {
        NavigationStack {
            // Replace this with whatever you're currently working on
            LessonListView()
                .navigationTitle("Current Development")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Authentication Debug View
struct AuthenticationDebugView: View {
    @State private var authState = "Not Authenticated"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Auth State: \(authState)")
                    .font(.headline)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Divider()
                
                // Sign in view
                ClassNotesSignInView(authService: MockAuthenticationService())
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Authentication Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Component Gallery View
struct ComponentGalleryView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Lesson Components") {
                    NavigationLink("Lesson Card") {
                        ScrollView {
                            VStack(spacing: 20) {
                                ForEach(MockData.sampleLessons) { lesson in
                                    LessonCard(lesson: lesson) {
                                        print("Tapped lesson: \(lesson.title)")
                                    }
                                    .previewAsComponent()
                                }
                            }
                            .padding()
                        }
                        .navigationTitle("Lesson Cards")
                    }
                    
                    NavigationLink("Lesson Detail") {
                        LessonDetailView(lesson: MockData.sampleLesson)
                    }
                }
                
                Section("Authentication Components") {
                    NavigationLink("Sign In View") {
                        ClassNotesSignInView(authService: MockAuthenticationService())
                            .previewAsComponent()
                    }
                    
                    NavigationLink("User Profile") {
                        UserProfileView(user: MockData.sampleUser)
                            .previewAsComponent()
                    }
                }
                
                Section("Common UI Elements") {
                    NavigationLink("Loading States") {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            
                            ProgressView("Loading lessons...")
                            
                            ProgressView("Syncing...", value: 0.7)
                        }
                        .padding()
                        .navigationTitle("Loading States")
                    }
                    
                    NavigationLink("Error States") {
                        VStack(spacing: 20) {
                            ErrorView(error: MockData.sampleError) {
                                print("Retry tapped")
                            }
                            .previewAsComponent()
                        }
                        .navigationTitle("Error States")
                    }
                }
            }
            .navigationTitle("Component Gallery")
        }
    }
}

// MARK: - Debug Settings View
struct DebugSettingsView: View {
    @AppStorage("debug_show_overlay") private var showDebugOverlay = false
    @AppStorage("debug_show_logs") private var showLogs = false
    @AppStorage("debug_mock_mode") private var useMockData = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Debug Options") {
                    Toggle("Show Debug Overlay", isOn: $showDebugOverlay)
                    Toggle("Show Console Logs", isOn: $showLogs)
                    Toggle("Use Mock Data", isOn: $useMockData)
                }
                
                Section("Device Info") {
                    LabeledContent("Device", value: UIDevice.current.name)
                    LabeledContent("iOS Version", value: UIDevice.current.systemVersion)
                    LabeledContent("App Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                }
                
                Section("Actions") {
                    Button("Clear Cache") {
                        print("Clearing cache...")
                    }
                    .foregroundColor(.red)
                    
                    Button("Reset App State") {
                        print("Resetting app state...")
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Debug Settings")
        }
    }
}

// MARK: - Placeholder Views (to be replaced with actual implementations)
struct LessonListView: View {
    var body: some View {
        List(MockData.sampleLessons) { lesson in
            LessonCard(lesson: lesson) { }
        }
        .navigationTitle("Lessons")
    }
}

struct LessonCard: View {
    let lesson: Lesson
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lesson.title)
                .font(.headline)
            Text(lesson.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Duration: \(lesson.duration / 60) minutes")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onTapGesture(perform: action)
    }
}

struct UserProfileView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text(user.displayName)
                .font(.title2)
            
            Text(user.email)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Debug Entry Point
struct DebugApp: App {
    var body: some Scene {
        WindowGroup {
            DebugView()
        }
    }
}

// MARK: - Previews
struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}
#endif 