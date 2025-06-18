import SwiftUI

/// Settings view for accessibility preferences
struct AccessibilitySettingsView: View {
    // MARK: - Properties
    
    @AppStorage("preferredTextSize") private var preferredTextSize: Double = 1.0
    @AppStorage("enableHighContrast") private var enableHighContrast = false
    @AppStorage("enableReduceMotion") private var enableReduceMotion = false
    @AppStorage("enableLargerTapTargets") private var enableLargerTapTargets = false
    @AppStorage("enableHapticFeedback") private var enableHapticFeedback = true
    @AppStorage("voiceOverAnnouncements") private var voiceOverAnnouncements = true
    @AppStorage("autoPlayAudio") private var autoPlayAudio = false
    @AppStorage("showCaptions") private var showCaptions = true
    
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Body
    
    var body: some View {
        List {
            // System settings info
            systemSettingsSection
            
            // Visual settings
            visualSettingsSection
            
            // Motion settings
            motionSettingsSection
            
            // Audio settings
            audioSettingsSection
            
            // VoiceOver settings
            voiceOverSettingsSection
            
            // Reset section
            resetSection
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var systemSettingsSection: some View {
        Section {
            // Current system settings
            VStack(alignment: .leading, spacing: 12) {
                SystemSettingRow(
                    title: "Text Size",
                    value: sizeCategory.description,
                    systemName: "textformat.size"
                )
                
                SystemSettingRow(
                    title: "Increase Contrast",
                    value: colorSchemeContrast == .increased ? "On" : "Off",
                    systemName: "circle.lefthalf.filled"
                )
                
                SystemSettingRow(
                    title: "Reduce Motion",
                    value: reduceMotion ? "On" : "Off",
                    systemName: "figure.walk.motion"
                )
                
                if AccessibilityUtilities.isVoiceOverRunning {
                    SystemSettingRow(
                        title: "VoiceOver",
                        value: "Active",
                        systemName: "speaker.wave.3"
                    )
                }
            }
            
            // Link to system settings
            Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                Label("Open System Settings", systemImage: "gear")
                    .foregroundColor(.accentColor)
            }
        } header: {
            Text("System Accessibility")
        } footer: {
            Text("Some settings are controlled by iOS. Tap above to open System Settings.")
        }
    }
    
    private var visualSettingsSection: some View {
        Section {
            // Text size adjustment
            VStack(alignment: .leading, spacing: 12) {
                Label("Text Size Adjustment", systemImage: "textformat.size")
                
                HStack {
                    Image(systemName: "textformat.size.smaller")
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: $preferredTextSize,
                        in: 0.8...1.5,
                        step: 0.1
                    ) {
                        Text("Text Size")
                    }
                    .accessibilityValue("\(Int(preferredTextSize * 100))% of default size")
                    
                    Image(systemName: "textformat.size.larger")
                        .foregroundColor(.secondary)
                }
                
                Text("Sample Text")
                    .font(.body)
                    .scaleEffect(preferredTextSize)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.vertical, 4)
            
            // High contrast toggle
            Toggle(isOn: $enableHighContrast) {
                Label("Force High Contrast", systemImage: "circle.lefthalf.filled")
            }
            
            // Larger tap targets
            Toggle(isOn: $enableLargerTapTargets) {
                Label("Larger Touch Targets", systemImage: "hand.tap")
            }
        } header: {
            Text("Visual")
        } footer: {
            Text("Adjust visual settings to improve readability and interaction.")
        }
    }
    
    private var motionSettingsSection: some View {
        Section {
            // Reduce motion
            Toggle(isOn: $enableReduceMotion) {
                Label("Reduce Motion", systemImage: "figure.walk.motion")
            }
            
            // Haptic feedback
            Toggle(isOn: $enableHapticFeedback) {
                Label("Haptic Feedback", systemImage: "waveform")
            }
            
            // Animation preview
            AnimationPreview(reduceMotion: enableReduceMotion)
                .padding(.vertical, 8)
        } header: {
            Text("Motion & Feedback")
        } footer: {
            Text("Control animations and haptic feedback throughout the app.")
        }
    }
    
    private var audioSettingsSection: some View {
        Section {
            // Auto-play audio
            Toggle(isOn: $autoPlayAudio) {
                Label("Auto-Play Audio", systemImage: "speaker.wave.2")
            }
            
            // Show captions
            Toggle(isOn: $showCaptions) {
                Label("Always Show Captions", systemImage: "captions.bubble")
            }
        } header: {
            Text("Audio & Captions")
        } footer: {
            Text("Control audio playback and caption display preferences.")
        }
    }
    
    private var voiceOverSettingsSection: some View {
        Section {
            // VoiceOver announcements
            Toggle(isOn: $voiceOverAnnouncements) {
                Label("Detailed Announcements", systemImage: "speaker.wave.3")
            }
            
            // VoiceOver hints
            VStack(alignment: .leading, spacing: 12) {
                Label("VoiceOver Tips", systemImage: "questionmark.circle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VoiceOverTip(
                    gesture: "Swipe Right",
                    action: "Navigate to next item"
                )
                
                VoiceOverTip(
                    gesture: "Double Tap",
                    action: "Activate selected item"
                )
                
                VoiceOverTip(
                    gesture: "Three Finger Swipe",
                    action: "Scroll through content"
                )
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("VoiceOver gesture tips")
        } header: {
            Text("VoiceOver")
        } footer: {
            Text("Enhance VoiceOver experience with detailed announcements.")
        }
    }
    
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                resetAccessibilitySettings()
            } label: {
                Label("Reset Accessibility Settings", systemImage: "arrow.counterclockwise")
            }
        } footer: {
            Text("Reset all accessibility preferences to default values.")
        }
    }
    
    // MARK: - Methods
    
    private func resetAccessibilitySettings() {
        preferredTextSize = 1.0
        enableHighContrast = false
        enableReduceMotion = false
        enableLargerTapTargets = false
        enableHapticFeedback = true
        voiceOverAnnouncements = true
        autoPlayAudio = false
        showCaptions = true
        
        HapticFeedback.success.trigger()
        AccessibilityUtilities.announce("Accessibility settings reset to defaults")
    }
}

// MARK: - Supporting Views

struct SystemSettingRow: View {
    let title: String
    let value: String
    let systemName: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: systemName)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct AnimationPreview: View {
    let reduceMotion: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Animation Preview")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                // Rotation animation
                Image(systemName: "gear")
                    .font(.title)
                    .foregroundColor(.accentColor)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        reduceMotion ? .none : .linear(duration: 2).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                // Scale animation
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 30, height: 30)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .animation(
                        reduceMotion ? .none : .easeInOut(duration: 1).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Position animation
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
                    .frame(width: 40, height: 20)
                    .offset(x: isAnimating ? 20 : -20)
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.6).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .onAppear {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Animation preview showing \(reduceMotion ? "no motion" : "standard animations")")
    }
}

struct VoiceOverTip: View {
    let gesture: String
    let action: String
    
    var body: some View {
        HStack {
            Text(gesture)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(action)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Size Category Extension

extension ContentSizeCategory {
    var description: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        case .extraExtraLarge: return "XXL"
        case .extraExtraExtraLarge: return "XXXL"
        case .accessibilityMedium: return "Accessibility M"
        case .accessibilityLarge: return "Accessibility L"
        case .accessibilityExtraLarge: return "Accessibility XL"
        case .accessibilityExtraExtraLarge: return "Accessibility XXL"
        case .accessibilityExtraExtraExtraLarge: return "Accessibility XXXL"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AccessibilitySettingsView()
    }
} 