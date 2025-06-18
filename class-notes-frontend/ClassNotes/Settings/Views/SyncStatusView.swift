import SwiftUI

/// View for displaying sync status and managing conflicts
struct SyncStatusView: View {
    // MARK: - Properties
    
    @StateObject private var offlineManager = OfflineDataManager.shared
    @State private var showingConflictResolution = false
    @State private var selectedConflict: SyncConflict?
    @State private var showingStorageManager = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            // Sync status section
            syncStatusSection
            
            // Storage section
            storageSection
            
            // Conflicts section
            if !offlineManager.conflicts.isEmpty {
                conflictsSection
            }
            
            // Actions section
            actionsSection
        }
        .navigationTitle("Sync & Storage")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedConflict) { conflict in
            ConflictResolutionView(conflict: conflict)
        }
        .sheet(isPresented: $showingStorageManager) {
            StorageManagerView()
        }
        .onAppear {
            offlineManager.startBackgroundSync()
        }
        .onDisappear {
            offlineManager.stopBackgroundSync()
        }
    }
    
    // MARK: - Sections
    
    private var syncStatusSection: some View {
        Section {
            HStack {
                statusIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.headline)
                    
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if case .syncing = offlineManager.syncStatus {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 8)
            
            if offlineManager.pendingChanges > 0 {
                Label("\(offlineManager.pendingChanges) changes pending", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        } header: {
            Text("Sync Status")
        }
    }
    
    private var storageSection: some View {
        Section {
            // Storage usage
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Storage Used")
                    Spacer()
                    Text(formatBytes(offlineManager.storageUsed))
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: Double(offlineManager.storageUsed), total: Double(offlineManager.storageQuota))
                    .tint(storageColor)
                
                Text("\(formatBytes(offlineManager.storageQuota - offlineManager.storageUsed)) available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            // Manage storage button
            Button {
                showingStorageManager = true
            } label: {
                Label("Manage Storage", systemImage: "internaldrive")
                    .foregroundColor(.primary)
            }
        } header: {
            Text("Offline Storage")
        } footer: {
            Text("Downloaded lessons are available offline and sync automatically when connected.")
        }
    }
    
    private var conflictsSection: some View {
        Section {
            ForEach(offlineManager.conflicts) { conflict in
                ConflictRow(conflict: conflict) {
                    selectedConflict = conflict
                }
            }
        } header: {
            Text("Sync Conflicts (\(offlineManager.conflicts.count))")
        } footer: {
            Text("Resolve conflicts to continue syncing affected lessons.")
        }
    }
    
    private var actionsSection: some View {
        Section {
            // Sync now button
            Button {
                Task {
                    await offlineManager.syncNow()
                }
            } label: {
                Label("Sync Now", systemImage: "arrow.clockwise")
                    .foregroundColor(.primary)
            }
            .disabled(offlineManager.syncStatus == .syncing)
            
            // Clear cache button
            Button(role: .destructive) {
                showClearCacheConfirmation()
            } label: {
                Label("Clear Offline Cache", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var statusIcon: some View {
        switch offlineManager.syncStatus {
        case .idle:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .syncing:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.blue)
                .symbolEffect(.rotate)
        case .completed(_, _):
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .hasConflicts:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }
    
    private var statusTitle: String {
        switch offlineManager.syncStatus {
        case .idle:
            return "Up to Date"
        case .syncing:
            return "Syncing..."
        case .completed(let uploaded, let downloaded):
            return "Sync Complete"
        case .hasConflicts(let count):
            return "\(count) Conflicts"
        case .failed:
            return "Sync Failed"
        }
    }
    
    private var statusDescription: String {
        switch offlineManager.syncStatus {
        case .idle:
            return "All changes synced"
        case .syncing:
            return "Uploading and downloading changes"
        case .completed(let uploaded, let downloaded):
            return "↑ \(uploaded) uploaded, ↓ \(downloaded) downloaded"
        case .hasConflicts:
            return "Manual resolution required"
        case .failed(let error):
            return error.localizedDescription
        }
    }
    
    private var storageColor: Color {
        let usage = Double(offlineManager.storageUsed) / Double(offlineManager.storageQuota)
        if usage > 0.9 {
            return .red
        } else if usage > 0.7 {
            return .orange
        } else {
            return .blue
        }
    }
    
    // MARK: - Methods
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
    
    private func showClearCacheConfirmation() {
        // TODO: Show confirmation alert
    }
}

// MARK: - Conflict Row

struct ConflictRow: View {
    let conflict: SyncConflict
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: conflictIcon)
                    .foregroundColor(.orange)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(conflict.localVersion.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(conflictDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var conflictIcon: String {
        switch conflict.conflictType {
        case .contentDiffers:
            return "doc.badge.ellipsis"
        case .deletedRemotely:
            return "trash.circle"
        case .modifiedBoth:
            return "arrow.triangle.branch"
        }
    }
    
    private var conflictDescription: String {
        switch conflict.conflictType {
        case .contentDiffers:
            return "Content differs between devices"
        case .deletedRemotely:
            return "Deleted on another device"
        case .modifiedBoth:
            return "Modified on multiple devices"
        }
    }
}

// MARK: - Conflict Resolution View

struct ConflictResolutionView: View {
    let conflict: SyncConflict
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedResolution: ConflictResolution?
    @State private var showingComparison = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Conflict info
                    conflictInfoSection
                    
                    // Version comparison
                    versionComparisonSection
                    
                    // Resolution options
                    resolutionOptionsSection
                    
                    // Apply button
                    if selectedResolution != nil {
                        applyButton
                    }
                }
                .padding()
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingComparison) {
                VersionComparisonView(conflict: conflict)
            }
        }
    }
    
    private var conflictInfoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Sync Conflict Detected")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("This lesson has been modified on multiple devices. Choose how to resolve the conflict.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var versionComparisonSection: some View {
        VStack(spacing: 12) {
            // Local version
            VersionCard(
                title: "This Device",
                subtitle: "Modified \(conflict.localVersion.lastModified.formatted())",
                icon: "iphone",
                color: .blue
            )
            
            // Remote version
            VersionCard(
                title: "Other Device",
                subtitle: "Modified \(conflict.remoteVersion.lastModified.formatted())",
                icon: "icloud",
                color: .purple
            )
            
            // Compare button
            Button {
                showingComparison = true
            } label: {
                Label("Compare Versions", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var resolutionOptionsSection: some View {
        VStack(spacing: 12) {
            Text("Choose Resolution")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ResolutionOption(
                title: "Keep This Device's Version",
                description: "Overwrite the version on other devices",
                icon: "iphone.circle.fill",
                color: .blue,
                isSelected: selectedResolution == .keepLocal
            ) {
                selectedResolution = .keepLocal
            }
            
            ResolutionOption(
                title: "Keep Other Device's Version",
                description: "Replace this device's version",
                icon: "icloud.circle.fill",
                color: .purple,
                isSelected: selectedResolution == .keepRemote
            ) {
                selectedResolution = .keepRemote
            }
            
            if conflict.conflictType == .contentDiffers {
                ResolutionOption(
                    title: "Merge Both Versions",
                    description: "Combine changes from both devices",
                    icon: "arrow.triangle.merge",
                    color: .green,
                    isSelected: selectedResolution == .merge
                ) {
                    selectedResolution = .merge
                }
            }
        }
    }
    
    private var applyButton: some View {
        Button {
            Task {
                await OfflineDataManager.shared.resolveConflict(conflict, resolution: selectedResolution!)
                dismiss()
            }
        } label: {
            Text("Apply Resolution")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}

// MARK: - Supporting Views

struct VersionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct ResolutionOption: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
        }
    }
}

// MARK: - Version Comparison View

struct VersionComparisonView: View {
    let conflict: SyncConflict
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // TODO: Implement side-by-side comparison
                    Text("Version comparison coming soon")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Compare Versions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Storage Manager View

struct StorageManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var offlineManager = OfflineDataManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // Storage summary
                Section {
                    StorageBreakdownView()
                } header: {
                    Text("Storage Breakdown")
                }
                
                // Manage downloads
                Section {
                    Button {
                        // TODO: Show downloaded lessons
                    } label: {
                        Label("Downloaded Lessons", systemImage: "square.and.arrow.down")
                            .foregroundColor(.primary)
                    }
                    
                    Button {
                        // TODO: Show cached files
                    } label: {
                        Label("Cached Files", systemImage: "doc.on.doc")
                            .foregroundColor(.primary)
                    }
                } header: {
                    Text("Manage Content")
                }
                
                // Actions
                Section {
                    Button(role: .destructive) {
                        Task {
                            try await offlineManager.clearOfflineCache()
                        }
                    } label: {
                        Label("Clear All Downloads", systemImage: "trash")
                    }
                } footer: {
                    Text("This will remove all offline content. You'll need to download it again for offline use.")
                }
            }
            .navigationTitle("Manage Storage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StorageBreakdownView: View {
    @State private var lessons: Double = 2.5
    @State private var documents: Double = 1.2
    @State private var cache: Double = 0.8
    
    private var total: Double {
        lessons + documents + cache
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Pie chart placeholder
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 150, height: 150)
                
                VStack {
                    Text(formatGB(total))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Breakdown
            VStack(spacing: 12) {
                StorageRow(label: "Lessons", value: lessons, color: .blue)
                StorageRow(label: "Documents", value: documents, color: .green)
                StorageRow(label: "Cache", value: cache, color: .orange)
            }
        }
        .padding(.vertical)
    }
    
    private func formatGB(_ value: Double) -> String {
        String(format: "%.1f GB", value)
    }
}

struct StorageRow: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(String(format: "%.1f GB", value))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Extensions

extension OfflineDataManager {
    static let shared = OfflineDataManager()
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SyncStatusView()
    }
} 