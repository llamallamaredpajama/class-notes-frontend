// 1. Standard library
import SwiftUI

/// Privacy settings and data management view
struct PrivacySettingsView: View {
    // MARK: - Properties
    @AppStorage("analyticsEnabled") private var analyticsEnabled = true
    @AppStorage("crashReportingEnabled") private var crashReportingEnabled = true
    @AppStorage("shareUsageData") private var shareUsageData = false
    @AppStorage("faceIDEnabled") private var faceIDEnabled = false
    @AppStorage("autoLockEnabled") private var autoLockEnabled = true
    @AppStorage("autoLockTimeout") private var autoLockTimeout = 5
    @State private var showingDeleteDataAlert = false
    @State private var showingExportDataAlert = false

    private let autoLockOptions = [1, 5, 15, 30]

    // MARK: - Body
    var body: some View {
        List {
            dataCollectionSection
            securitySection
            dataManagementSection
        }
        .navigationTitle("Privacy")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
        .alert("Delete All Data", isPresented: $showingDeleteDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text(
                "This will permanently delete all your notes, recordings, and app data. This action cannot be undone."
            )
        }
        .alert("Export Data", isPresented: $showingExportDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Export") {
                exportData()
            }
        } message: {
            Text("Your data will be exported in JSON format and saved to your device.")
        }
    }

    // MARK: - Views
    @ViewBuilder
    private var dataCollectionSection: some View {
        Section {
            Toggle("Analytics", isOn: $analyticsEnabled)
            Toggle("Crash Reporting", isOn: $crashReportingEnabled)
            Toggle("Share Usage Data", isOn: $shareUsageData)
        } header: {
            Text("Data Collection")
        } footer: {
            Text(
                "We use this data to improve the app experience. No personal information is collected."
            )
        }
    }

    @ViewBuilder
    private var securitySection: some View {
        Section {
            #if os(iOS)
                Toggle("Face ID / Touch ID", isOn: $faceIDEnabled)
            #endif

            Toggle("Auto-Lock", isOn: $autoLockEnabled)

            if autoLockEnabled {
                Picker("Auto-Lock Timeout", selection: $autoLockTimeout) {
                    ForEach(autoLockOptions, id: \.self) { minutes in
                        Text("\(minutes) minute\(minutes == 1 ? "" : "s")").tag(minutes)
                    }
                }
            }

            NavigationLink(destination: BlockedContactsView()) {
                HStack {
                    Text("Blocked Contacts")
                    Spacer()
                    Text("None")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Security")
        }
    }

    @ViewBuilder
    private var dataManagementSection: some View {
        Section {
            Button(action: { showingExportDataAlert = true }) {
                Label("Export My Data", systemImage: "square.and.arrow.up")
            }

            NavigationLink(destination: DataUsageView()) {
                Label("Storage Usage", systemImage: "internaldrive")
            }

            Button(role: .destructive, action: { showingDeleteDataAlert = true }) {
                Label("Delete All Data", systemImage: "trash")
                    .foregroundColor(.red)
            }
        } header: {
            Text("Data Management")
        } footer: {
            Text("Export your data or permanently delete all app data from your device.")
        }
    }

    // MARK: - Functions
    private func deleteAllData() {
        // Implement data deletion logic
        print("Deleting all data...")
    }

    private func exportData() {
        // Implement data export logic
        print("Exporting data...")
    }
}

// MARK: - Supporting Views
struct BlockedContactsView: View {
    @State private var blockedContacts: [String] = []

    var body: some View {
        List {
            if blockedContacts.isEmpty {
                ContentUnavailableView(
                    "No Blocked Contacts",
                    systemImage: "person.crop.circle.badge.xmark",
                    description: Text("You haven't blocked any contacts.")
                )
            } else {
                ForEach(blockedContacts, id: \.self) { contact in
                    Text(contact)
                }
                .onDelete { indices in
                    blockedContacts.remove(atOffsets: indices)
                }
            }
        }
        .navigationTitle("Blocked Contacts")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            EditButton()
        }
    }
}

struct DataUsageView: View {
    @State private var audioSize: Int64 = 524_288_000  // 500 MB
    @State private var notesSize: Int64 = 10_485_760  // 10 MB
    @State private var cacheSize: Int64 = 104_857_600  // 100 MB

    private var totalSize: Int64 {
        audioSize + notesSize + cacheSize
    }

    var body: some View {
        List {
            Section {
                DataUsageRow(title: "Audio Recordings", size: audioSize, color: .blue)
                DataUsageRow(title: "Notes & Transcriptions", size: notesSize, color: .green)
                DataUsageRow(title: "Cache", size: cacheSize, color: .orange)
            }

            Section {
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(formatBytes(totalSize))
                        .font(.headline)
                }
            }

            Section {
                Button(action: clearCache) {
                    Label("Clear Cache", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Storage Usage")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func clearCache() {
        cacheSize = 0
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct DataUsageRow: View {
    let title: String
    let size: Int64
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(title)
            Spacer()
            Text(formatBytes(size))
                .foregroundColor(.secondary)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
