// 1. Standard library
import SwiftUI

/// User preferences and app settings view
struct PreferencesView: View {
    // MARK: - Properties
    @AppStorage("audioQuality") private var audioQuality = "medium"
    @AppStorage("autoTranscribe") private var autoTranscribe = true
    @AppStorage("saveOriginalAudio") private var saveOriginalAudio = true
    @AppStorage("defaultNoteDuration") private var defaultNoteDuration = 60.0
    @AppStorage("theme") private var theme = "system"

    private let audioQualities = ["low", "medium", "high"]
    private let themes = ["system", "light", "dark"]

    // MARK: - Body
    var body: some View {
        List {
            audioSection
            transcriptionSection
            appearanceSection
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Views
    @ViewBuilder
    private var audioSection: some View {
        Section("Audio Settings") {
            Picker("Audio Quality", selection: $audioQuality) {
                Text("Low").tag("low")
                Text("Medium").tag("medium")
                Text("High").tag("high")
            }

            Toggle("Save Original Audio", isOn: $saveOriginalAudio)

            HStack {
                Text("Default Recording Duration")
                Spacer()
                Text("\(Int(defaultNoteDuration)) min")
                    .foregroundColor(.secondary)
            }
            Slider(value: $defaultNoteDuration, in: 15...120, step: 15) {
                Text("Duration")
            }
        }
    }

    @ViewBuilder
    private var transcriptionSection: some View {
        Section("Transcription") {
            Toggle("Auto-transcribe on Save", isOn: $autoTranscribe)

            NavigationLink(destination: TranscriptionLanguagesView()) {
                HStack {
                    Text("Languages")
                    Spacer()
                    Text("English")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $theme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Supporting Views
struct TranscriptionLanguagesView: View {
    var body: some View {
        List {
            HStack {
                Text("English")
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
            Text("Spanish")
                .foregroundColor(.secondary)
            Text("French")
                .foregroundColor(.secondary)
            Text("German")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Languages")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PreferencesView()
    }
}
