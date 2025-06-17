// 2. Apple frameworks
import SwiftData
// 1. Standard library
import SwiftUI

/// User profile view with settings and account management
struct ProfileView: View {
    // MARK: - Properties
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @Query private var users: [User]
    @State private var showingSignOutAlert = false

    private var currentUser: User? {
        users.first
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                userInfoSection
                preferencesSection
                aboutSection
                accountActionsSection
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    // MARK: - Views
    @ViewBuilder
    private var userInfoSection: some View {
        if let user = currentUser {
            Section {
                HStack {
                    userProfileImage(for: user)
                    userInfoDetails(for: user)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private func userProfileImage(for user: User) -> some View {
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
    }

    @ViewBuilder
    private func userInfoDetails(for user: User) -> some View {
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
    }

    @ViewBuilder
    private var preferencesSection: some View {
        Section("Preferences") {
            NavigationLink(destination: SubscriptionView()) {
                Label("Subscription", systemImage: "creditcard")
            }

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
    }

    @ViewBuilder
    private var aboutSection: some View {
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
    }

    @ViewBuilder
    private var accountActionsSection: some View {
        Section {
            Button(role: .destructive) {
                showingSignOutAlert = true
            } label: {
                Label("Sign Out", systemImage: "arrow.right.square")
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(AuthenticationViewModel(authService: MockAuthenticationService()))
        .modelContainer(PersistenceController.preview.container)
}
