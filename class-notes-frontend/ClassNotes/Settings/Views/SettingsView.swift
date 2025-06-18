import SwiftUI
import StoreKit

/// Main settings view providing access to all app settings and preferences
struct SettingsView: View {
    // MARK: - Properties
    
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                accountSection
                subscriptionSection
                preferencesSection
                privacySection
                supportSection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Account", role: .destructive) {
                    Task {
                        // TODO: Implement account deletion
                        // await authViewModel.deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Sections
    
    private var accountSection: some View {
        Section {
            // User profile row
            HStack {
                if let photoURL = authViewModel.currentUser?.profileImageURL {
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authViewModel.currentUser?.displayName ?? "User")
                        .font(.headline)
                    Text(authViewModel.currentUser?.email ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            
            // Account actions
            Button {
                showingSignOutAlert = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.primary)
            }
            
            Button {
                showingDeleteAccountAlert = true
            } label: {
                Label("Delete Account", systemImage: "trash")
                    .foregroundColor(.red)
            }
        } header: {
            Text("Account")
        }
    }
    
    private var subscriptionSection: some View {
        Section {
            NavigationLink(destination: SubscriptionView()) {
                HStack {
                    Label("Subscription", systemImage: "creditcard")
                    Spacer()
                    Text("Basic")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Subscription")
        } footer: {
            Text("Manage your subscription and view available plans")
        }
    }
    
    private var preferencesSection: some View {
        Section {
            NavigationLink(destination: PreferencesView()) {
                Label("General", systemImage: "gearshape")
            }
            
            NavigationLink(destination: NotificationSettingsView()) {
                Label("Notifications", systemImage: "bell")
            }
            
            NavigationLink(destination: AudioSettingsView()) {
                Label("Audio & Recording", systemImage: "waveform")
            }
            
            NavigationLink(destination: StorageSettingsView()) {
                Label("Storage", systemImage: "internaldrive")
            }
        } header: {
            Text("Preferences")
        }
    }
    
    private var privacySection: some View {
        Section {
            NavigationLink(destination: PrivacySettingsView()) {
                Label("Privacy", systemImage: "lock")
            }
            
            Link(destination: URL(string: "https://classnotes.app/privacy")!) {
                HStack {
                    Label("Privacy Policy", systemImage: "doc.text")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            Link(destination: URL(string: "https://classnotes.app/terms")!) {
                HStack {
                    Label("Terms of Service", systemImage: "doc.text")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Text("Privacy & Legal")
        }
    }
    
    private var supportSection: some View {
        Section {
            NavigationLink(destination: HelpView()) {
                Label("Help & Support", systemImage: "questionmark.circle")
            }
            
            Link(destination: URL(string: "mailto:support@classnotes.app")!) {
                HStack {
                    Label("Contact Support", systemImage: "envelope")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            Button {
                requestAppStoreReview()
            } label: {
                Label("Rate Class Notes", systemImage: "star")
                    .foregroundColor(.primary)
            }
        } header: {
            Text("Support")
        }
    }
    
    private var aboutSection: some View {
        Section {
            NavigationLink(destination: AboutView()) {
                HStack {
                    Label("About", systemImage: "info.circle")
                    Spacer()
                    Text("Version \(appVersion)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            NavigationLink(destination: AcknowledgementsView()) {
                Label("Acknowledgements", systemImage: "heart")
            }
        } header: {
            Text("About")
        }
    }
    
    // MARK: - Helpers
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private func requestAppStoreReview() {
        #if !targetEnvironment(simulator)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        #endif
    }
}

// MARK: - Additional Settings Views

struct AudioSettingsView: View {
    @AppStorage("audioQuality") private var audioQuality = "high"
    @AppStorage("pauseOnInterruption") private var pauseOnInterruption = true
    @AppStorage("backgroundRecording") private var backgroundRecording = true
    @AppStorage("silenceDetection") private var silenceDetection = true
    
    var body: some View {
        Form {
            Section {
                Picker("Audio Quality", selection: $audioQuality) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }
                
                Toggle("Pause on Interruption", isOn: $pauseOnInterruption)
                Toggle("Background Recording", isOn: $backgroundRecording)
                Toggle("Silence Detection", isOn: $silenceDetection)
            } header: {
                Text("Recording Settings")
            } footer: {
                Text("Higher quality audio will use more storage space")
            }
            
            Section {
                HStack {
                    Text("Microphone")
                    Spacer()
                    Text("Built-in Microphone")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Input Device")
            }
        }
        .navigationTitle("Audio & Recording")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StorageSettingsView: View {
    @State private var usedStorage: Int64 = 0
    @State private var totalStorage: Int64 = 0
    @AppStorage("autoDeleteOldRecordings") private var autoDeleteOldRecordings = false
    @AppStorage("keepRecordingsDays") private var keepRecordingsDays = 30
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Used")
                        Spacer()
                        Text(formatBytes(usedStorage))
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: Double(usedStorage), total: Double(totalStorage))
                        .tint(.accentColor)
                    
                    HStack {
                        Text("Available")
                        Spacer()
                        Text(formatBytes(totalStorage - usedStorage))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Storage Usage")
            }
            
            Section {
                Toggle("Auto-delete Old Recordings", isOn: $autoDeleteOldRecordings)
                
                if autoDeleteOldRecordings {
                    Stepper("Keep for \(keepRecordingsDays) days", 
                           value: $keepRecordingsDays, 
                           in: 7...90, 
                           step: 7)
                }
                
                Button("Clear Cache") {
                    // TODO: Implement cache clearing
                }
                .foregroundColor(.red)
            } header: {
                Text("Storage Management")
            }
        }
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            calculateStorageUsage()
        }
    }
    
    private func calculateStorageUsage() {
        // TODO: Calculate actual storage usage
        usedStorage = 1_073_741_824 // 1 GB for demo
        totalStorage = 5_368_709_120 // 5 GB for demo
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct AcknowledgementsView: View {
    var body: some View {
        List {
            Section {
                Link("SwiftUI", destination: URL(string: "https://developer.apple.com/xcode/swiftui/")!)
                Link("gRPC Swift", destination: URL(string: "https://github.com/grpc/grpc-swift")!)
                Link("Google Sign-In", destination: URL(string: "https://developers.google.com/identity/sign-in/ios")!)
                Link("WhisperKit", destination: URL(string: "https://github.com/argmaxinc/WhisperKit")!)
            } header: {
                Text("Open Source Libraries")
            }
            
            Section {
                Text("Class Notes is built with love by a dedicated team of developers who believe in making education more accessible and effective for everyone.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } header: {
                Text("Thank You")
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthenticationViewModel(authService: MockAuthenticationService()))
} 