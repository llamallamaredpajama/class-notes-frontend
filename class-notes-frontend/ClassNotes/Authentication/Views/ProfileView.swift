import SwiftUI
import SwiftData

/// User profile view with settings and account management
struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Query private var users: [User]
    @State private var showingSignOutAlert = false
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                if let user = currentUser {
                    Section {
                        HStack {
                            if let profileImageURL = user.profileImageURL {
                                AsyncImage(url: profileImageURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text(user.authProvider.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Preferences Section
                Section("Preferences") {
                    NavigationLink(destination: PreferencesView()) {
                        Label("Preferences", systemImage: "gearshape")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy", systemImage: "lock")
                    }
                }
                
                // App Information Section
                Section("About") {
                    NavigationLink(destination: AboutView()) {
                        Label("About Class Notes", systemImage: "info.circle")
                    }
                    
                    NavigationLink(destination: HelpView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    Link(destination: URL(string: "https://classnotes.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "doc.text")
                    }
                    
                    Link(destination: URL(string: "https://classnotes.app/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
                
                // Account Actions Section
                Section {
                    Button(role: .destructive) {
                        showingSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Placeholder Views

struct PreferencesView: View {
    var body: some View {
        Text("Preferences")
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        Text("About Class Notes")
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        Text("Help & Support")
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationViewModel(authService: MockAuthenticationService()))
        .modelContainer(PersistenceController.preview.container)
} 