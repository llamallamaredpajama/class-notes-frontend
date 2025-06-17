// 1. Standard library
import SwiftUI

/// Notification preferences and settings view
struct NotificationSettingsView: View {
    // MARK: - Properties
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("transcriptionCompleteNotifications") private var transcriptionComplete = true
    @AppStorage("dailyReminderEnabled") private var dailyReminder = false
    @AppStorage("dailyReminderTime") private var dailyReminderTime = Date()
    @AppStorage("weeklyReportEnabled") private var weeklyReport = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("badgeEnabled") private var badgeEnabled = true

    // MARK: - Body
    var body: some View {
        List {
            masterToggleSection
            if notificationsEnabled {
                notificationTypesSection
                scheduleSection
                notificationStyleSection
            }
        }
        .navigationTitle("Notifications")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Views
    @ViewBuilder
    private var masterToggleSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
        } footer: {
            Text(
                "Control all app notifications. You can customize specific notification types below."
            )
        }
    }

    @ViewBuilder
    private var notificationTypesSection: some View {
        Section("Notification Types") {
            Toggle("Transcription Complete", isOn: $transcriptionComplete)

            HStack {
                Label("Daily Study Reminder", systemImage: "clock")
                Toggle("", isOn: $dailyReminder)
            }

            if dailyReminder {
                DatePicker(
                    "Reminder Time",
                    selection: $dailyReminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
            }

            Toggle("Weekly Progress Report", isOn: $weeklyReport)
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        Section("Schedule") {
            NavigationLink(destination: QuietHoursView()) {
                HStack {
                    Label("Quiet Hours", systemImage: "moon")
                    Spacer()
                    Text("Off")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var notificationStyleSection: some View {
        Section("Notification Style") {
            Toggle("Sound", isOn: $soundEnabled)
            Toggle("Badge App Icon", isOn: $badgeEnabled)

            NavigationLink(destination: NotificationSoundsView()) {
                HStack {
                    Text("Notification Sound")
                    Spacer()
                    Text("Default")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct QuietHoursView: View {
    @State private var quietHoursEnabled = false
    @State private var startTime = Date()
    @State private var endTime = Date()

    var body: some View {
        List {
            Section {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)

                if quietHoursEnabled {
                    DatePicker(
                        "Start Time",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute)

                    DatePicker(
                        "End Time",
                        selection: $endTime,
                        displayedComponents: .hourAndMinute)
                }
            } footer: {
                Text("During quiet hours, notifications will be delivered silently.")
            }
        }
        .navigationTitle("Quiet Hours")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct NotificationSoundsView: View {
    @State private var selectedSound = "default"
    private let sounds = ["Default", "Chime", "Bell", "Success", "Alert"]

    var body: some View {
        List {
            ForEach(sounds, id: \.self) { sound in
                HStack {
                    Text(sound)
                    Spacer()
                    if sound.lowercased() == selectedSound {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSound = sound.lowercased()
                }
            }
        }
        .navigationTitle("Notification Sound")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
