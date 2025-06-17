// 1. Standard library
import SwiftUI

/// About page showing app information and credits
struct AboutView: View {
    // MARK: - Properties
    private let appVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    @State private var showingAcknowledgments = false

    // MARK: - Body
    var body: some View {
        List {
            appInfoSection
            teamSection
            linksSection
            legalSection
        }
        .navigationTitle("About")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Views
    @ViewBuilder
    private var appInfoSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "note.text")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)

                Text("Class Notes")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your AI-powered study companion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Version \(appVersion)")
                    Text("(\(buildNumber))")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    @ViewBuilder
    private var teamSection: some View {
        Section("Team") {
            TeamMemberRow(
                name: "John Doe",
                role: "Founder & CEO",
                imageName: "person.circle.fill"
            )

            TeamMemberRow(
                name: "Jane Smith",
                role: "Lead Developer",
                imageName: "person.circle.fill"
            )

            TeamMemberRow(
                name: "Mike Johnson",
                role: "Head of Design",
                imageName: "person.circle.fill"
            )
        }
    }

    @ViewBuilder
    private var linksSection: some View {
        Section("Connect") {
            Link(destination: URL(string: "https://classnotes.app")!) {
                Label("Website", systemImage: "globe")
            }

            Link(destination: URL(string: "https://twitter.com/classnotesapp")!) {
                Label("Twitter", systemImage: "at")
            }

            Link(destination: URL(string: "mailto:support@classnotes.app")!) {
                Label("Contact Support", systemImage: "envelope")
            }

            NavigationLink(destination: AcknowledgmentsView()) {
                Label("Acknowledgments", systemImage: "heart")
            }
        }
    }

    @ViewBuilder
    private var legalSection: some View {
        Section("Legal") {
            Link(destination: URL(string: "https://classnotes.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }

            Link(destination: URL(string: "https://classnotes.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
            }

            NavigationLink(destination: LicensesView()) {
                Label("Open Source Licenses", systemImage: "doc.on.doc")
            }
        }
    }
}

// MARK: - Supporting Views
struct TeamMemberRow: View {
    let name: String
    let role: String
    let imageName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: imageName)
                .font(.system(size: 40))
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                Text(role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AcknowledgmentsView: View {
    var body: some View {
        List {
            Section {
                Text(
                    "We would like to thank the following open source projects and their contributors:"
                )
                .padding(.vertical, 8)
            }

            Section("Libraries") {
                AcknowledgmentRow(
                    title: "Firebase", description: "Backend infrastructure and authentication")
                AcknowledgmentRow(title: "Google Sign-In", description: "Secure authentication")
                AcknowledgmentRow(title: "SwiftProtobuf", description: "Protocol buffer support")
                AcknowledgmentRow(title: "GRPC-Swift", description: "gRPC client implementation")
            }

            Section("Special Thanks") {
                Text(
                    "To all our beta testers and early adopters who helped shape Class Notes into what it is today."
                )
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Acknowledgments")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct AcknowledgmentRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct LicensesView: View {
    var body: some View {
        List {
            LicenseRow(
                library: "Firebase iOS SDK",
                license: "Apache License 2.0",
                url: "https://github.com/firebase/firebase-ios-sdk/blob/master/LICENSE"
            )

            LicenseRow(
                library: "Google Sign-In for iOS",
                license: "Apache License 2.0",
                url: "https://github.com/google/GoogleSignIn-iOS/blob/main/LICENSE"
            )

            LicenseRow(
                library: "Swift Protobuf",
                license: "Apache License 2.0",
                url: "https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt"
            )

            LicenseRow(
                library: "gRPC Swift",
                license: "Apache License 2.0",
                url: "https://github.com/grpc/grpc-swift/blob/main/LICENSE"
            )
        }
        .navigationTitle("Open Source Licenses")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct LicenseRow: View {
    let library: String
    let license: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(alignment: .leading, spacing: 4) {
                Text(library)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(license)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AboutView()
    }
}
