#if DEBUG
    import SwiftUI
    import SwiftData
    #if canImport(UIKit)
        import UIKit
    #endif

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
                    ClassNotesSignInView()
                        .environmentObject(
                            AuthenticationViewModel(authService: MockAuthenticationService())
                        )
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
                    Section {
                        NavigationLink("Lesson Card") {
                            Text("Lesson Card Gallery")
                                .navigationTitle("Lesson Cards")
                        }

                        NavigationLink("Lesson Detail") {
                            Text("Lesson Detail View")
                                .navigationTitle("Lesson Detail")
                        }
                    } header: {
                        Text("Lesson Components")
                    }

                    Section {
                        NavigationLink("Sign In View") {
                            Text("Sign In View")
                                .navigationTitle("Sign In")
                        }

                        NavigationLink("User Profile") {
                            Text("User Profile View")
                                .navigationTitle("Profile")
                        }
                    } header: {
                        Text("Authentication Components")
                    }

                    Section {
                        NavigationLink("Loading States") {
                            Text("Loading States")
                                .navigationTitle("Loading States")
                        }

                        NavigationLink("Error States") {
                            Text("Error States")
                                .navigationTitle("Error States")
                        }
                    } header: {
                        Text("Common UI Elements")
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
                    Section {
                        Toggle("Show Debug Overlay", isOn: $showDebugOverlay)
                        Toggle("Show Console Logs", isOn: $showLogs)
                        Toggle("Use Mock Data", isOn: $useMockData)
                    } header: {
                        Text("Debug Options")
                    }

                    Section {
                        #if canImport(UIKit)
                            LabeledContent("Device", value: UIDevice.current.name)
                            LabeledContent("iOS Version", value: UIDevice.current.systemVersion)
                        #else
                            LabeledContent("Platform", value: "iOS")
                        #endif
                        LabeledContent(
                            "App Version",
                            value: Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                                as? String ?? "Unknown")
                    } header: {
                        Text("Device Info")
                    }

                    Section {
                        Button("Clear Cache") {
                            print("Clearing cache...")
                        }
                        .foregroundColor(.red)

                        Button("Reset App State") {
                            print("Resetting app state...")
                        }
                        .foregroundColor(.red)
                    } header: {
                        Text("Actions")
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
                PreviewLessonCard(lesson: lesson) {}
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

    struct PreviewLessonCard: View {
        let lesson: MockData.PreviewLesson
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

    struct DebugErrorView: View {
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

    // MARK: - Helper Views for Complex Expressions
    struct LessonCardGalleryView: View {
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(MockData.sampleLessons) { lesson in
                        PreviewLessonCard(lesson: lesson) {
                            print("Tapped lesson: \(lesson.title)")
                        }
                        .previewAsComponent()
                    }
                }
                .padding()
            }
        }
    }

    struct LoadingStatesView: View {
        var body: some View {
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())

                ProgressView("Loading lessons...")

                ProgressView("Syncing...", value: 0.7)
            }
            .padding()
        }
    }

    struct ErrorStatesView: View {
        var body: some View {
            VStack(spacing: 20) {
                DebugErrorView(error: MockData.sampleError) {
                    print("Retry tapped")
                }
                .previewAsComponent()
            }
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
