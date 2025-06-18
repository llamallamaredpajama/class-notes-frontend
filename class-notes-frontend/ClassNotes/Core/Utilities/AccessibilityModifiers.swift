import SwiftUI

// MARK: - Accessibility View Modifiers

extension View {
    
    /// Adds comprehensive accessibility support to a view
    func accessibilityElement(
        label: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        value: String? = nil
    ) -> some View {
        self.modifier(AccessibilityElementModifier(
            label: label,
            hint: hint,
            traits: traits,
            value: value
        ))
    }
    
    /// Makes view adapt to Dynamic Type settings
    func dynamicTypeAccessible(
        minimumScaleFactor: CGFloat = 0.5,
        lineLimit: Int? = nil
    ) -> some View {
        self.modifier(DynamicTypeModifier(
            minimumScaleFactor: minimumScaleFactor,
            lineLimit: lineLimit
        ))
    }
    
    /// Respects reduce motion preference
    func reduceMotionAware() -> some View {
        self.modifier(ReduceMotionModifier())
    }
    
    /// Adapts to high contrast mode
    func highContrastAware() -> some View {
        self.modifier(HighContrastModifier())
    }
    
    /// Adds focus management for VoiceOver
    func accessibilityFocusable(
        focused: Binding<Bool>,
        onFocusChange: ((Bool) -> Void)? = nil
    ) -> some View {
        self.modifier(AccessibilityFocusModifier(
            focused: focused,
            onFocusChange: onFocusChange
        ))
    }
    
    /// Makes interactive elements more accessible
    func accessibleTapTarget(
        minimumSize: CGSize = CGSize(width: 44, height: 44)
    ) -> some View {
        self.modifier(AccessibleTapTargetModifier(minimumSize: minimumSize))
    }
    
    /// Adds custom rotor for VoiceOver navigation
    func accessibilityRotor<RotorContent>(
        _ title: String,
        @ViewBuilder content: @escaping () -> RotorContent
    ) -> some View where RotorContent: View {
        self.modifier(AccessibilityRotorModifier(title: title, rotorContent: content))
    }
    
    /// Groups elements for better VoiceOver navigation
    func accessibilityContainer(
        label: String,
        isContainer: Bool = true
    ) -> some View {
        self.modifier(AccessibilityContainerModifier(
            label: label,
            isContainer: isContainer
        ))
    }
}

// MARK: - Accessibility Element Modifier

struct AccessibilityElementModifier: ViewModifier {
    let label: String?
    let hint: String?
    let traits: AccessibilityTraits
    let value: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityValue(value ?? "")
    }
}

// MARK: - Dynamic Type Modifier

struct DynamicTypeModifier: ViewModifier {
    let minimumScaleFactor: CGFloat
    let lineLimit: Int?
    
    @Environment(\.sizeCategory) private var sizeCategory
    
    func body(content: Content) -> some View {
        content
            .minimumScaleFactor(minimumScaleFactor)
            .lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: !sizeCategory.isAccessibilityCategory)
    }
}

// MARK: - Reduce Motion Modifier

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? .none : .default, value: reduceMotion)
            .transaction { transaction in
                if reduceMotion {
                    transaction.animation = nil
                }
            }
    }
}

// MARK: - High Contrast Modifier

struct HighContrastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(adaptedForegroundColor)
            .background(adaptedBackgroundColor)
    }
    
    private var adaptedForegroundColor: Color {
        colorSchemeContrast == .increased ? .primary : .primary.opacity(0.9)
    }
    
    private var adaptedBackgroundColor: Color {
        colorSchemeContrast == .increased ? Color(.systemBackground) : Color.clear
    }
}

// MARK: - Accessibility Focus Modifier

struct AccessibilityFocusModifier: ViewModifier {
    @Binding var focused: Bool
    let onFocusChange: ((Bool) -> Void)?
    
    @AccessibilityFocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused)
            .onChange(of: focused) { _, newValue in
                isFocused = newValue
            }
            .onChange(of: isFocused) { _, newValue in
                focused = newValue
                onFocusChange?(newValue)
            }
    }
}

// MARK: - Accessible Tap Target Modifier

struct AccessibleTapTargetModifier: ViewModifier {
    let minimumSize: CGSize
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: minimumSize.width, minHeight: minimumSize.height)
            .contentShape(Rectangle())
    }
}

// MARK: - Accessibility Rotor Modifier

struct AccessibilityRotorModifier<RotorContent: View>: ViewModifier {
    let title: String
    let rotorContent: () -> RotorContent
    
    func body(content: Content) -> some View {
        content
            .accessibilityRotor(title) {
                self.rotorContent()
            }
    }
}

// MARK: - Accessibility Container Modifier

struct AccessibilityContainerModifier: ViewModifier {
    let label: String
    let isContainer: Bool
    
    func body(content: Content) -> some View {
        if isContainer {
            content
                .accessibilityElement(children: .contain)
                .accessibilityLabel(label)
        } else {
            content
                .accessibilityElement(children: .combine)
                .accessibilityLabel(label)
        }
    }
}

// MARK: - Accessibility Utilities

struct AccessibilityUtilities {
    
    /// Checks if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    /// Checks if reduce motion is enabled
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Checks if bold text is enabled
    static var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }
    
    /// Checks if high contrast is enabled
    static var isDarkerSystemColorsEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// Posts accessibility notification
    static func post(notification: UIAccessibility.Notification, argument: Any? = nil) {
        UIAccessibility.post(notification: notification, argument: argument)
    }
    
    /// Announces message to VoiceOver
    static func announce(_ message: String) {
        post(notification: .announcement, argument: message)
    }
    
    /// Notifies screen change
    static func announceScreenChange(_ message: String? = nil) {
        post(notification: .screenChanged, argument: message)
    }
    
    /// Notifies layout change
    static func announceLayoutChange(_ message: String? = nil) {
        post(notification: .layoutChanged, argument: message)
    }
}

// MARK: - Accessible Color Extensions

extension Color {
    
    /// Returns a color that meets WCAG contrast requirements
    func accessibleColor(for background: Color, targetContrast: Double = 4.5) -> Color {
        // Simple implementation - in production, calculate actual contrast ratio
        if background == .black {
            return .white
        } else if background == .white {
            return .black
        } else {
            return self
        }
    }
    
    /// High contrast variant of the color
    var highContrast: Color {
        // Simplified - would need proper color manipulation
        return self
    }
}

// MARK: - Accessible Icons

struct AccessibleIcon: View {
    let systemName: String
    let label: String
    var decorative: Bool = false
    
    var body: some View {
        Image(systemName: systemName)
            .accessibilityLabel(decorative ? "" : label)
            .accessibilityHidden(decorative)
    }
}

// MARK: - Accessible Loading View

struct AccessibleLoadingView: View {
    let message: String
    
    @State private var announcementTimer: Timer?
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message). Loading in progress.")
        .accessibilityAddTraits(.updatesFrequently)
        .onAppear {
            // Announce loading state
            AccessibilityUtilities.announce(message)
            
            // Periodic updates for long operations
            announcementTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                AccessibilityUtilities.announce("Still loading. Please wait.")
            }
        }
        .onDisappear {
            announcementTimer?.invalidate()
            AccessibilityUtilities.announce("Loading complete")
        }
    }
}

// MARK: - Accessible Error View

struct AccessibleErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
                .accessibilityHidden(true)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .dynamicTypeAccessible()
            
            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.borderedProminent)
                    .accessibleTapTarget()
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error: \(error.localizedDescription)")
        .onAppear {
            AccessibilityUtilities.announce("Error occurred: \(error.localizedDescription)")
        }
    }
}

// MARK: - Accessible Empty State View

struct AccessibleEmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let action: (() -> Void)?
    let actionLabel: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .dynamicTypeAccessible()
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .dynamicTypeAccessible(lineLimit: 5)
            }
            
            if let action = action, let label = actionLabel {
                Button(label, action: action)
                    .buttonStyle(.borderedProminent)
                    .accessibleTapTarget()
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
    
    func trigger() {
        guard !AccessibilityUtilities.isReduceMotionEnabled else { return }
        
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

// MARK: - Accessible Progress View

struct AccessibleProgressView: View {
    let value: Double
    let total: Double
    let label: String
    
    private var percentage: Int {
        Int((value / total) * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: value, total: total)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(percentage)%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label). Progress: \(percentage) percent complete")
        .accessibilityValue("\(percentage) percent")
    }
}

// MARK: - Preview Helpers

struct AccessibilityPreview<Content: View>: View {
    let content: Content
    
    @State private var sizeCategory: ContentSizeCategory = .large
    @State private var colorSchemeContrast: ColorSchemeContrast = .standard
    @State private var accessibilityEnabled = false
    
    var body: some View {
        VStack {
            // Controls
            VStack(alignment: .leading, spacing: 12) {
                Text("Accessibility Preview")
                    .font(.headline)
                
                Picker("Text Size", selection: $sizeCategory) {
                    Text("Small").tag(ContentSizeCategory.small)
                    Text("Medium").tag(ContentSizeCategory.medium)
                    Text("Large").tag(ContentSizeCategory.large)
                    Text("Extra Large").tag(ContentSizeCategory.extraLarge)
                    Text("XXL").tag(ContentSizeCategory.extraExtraLarge)
                    Text("XXXL").tag(ContentSizeCategory.extraExtraExtraLarge)
                    Text("Accessibility M").tag(ContentSizeCategory.accessibilityMedium)
                    Text("Accessibility L").tag(ContentSizeCategory.accessibilityLarge)
                }
                .pickerStyle(.segmented)
                
                Toggle("High Contrast", isOn: Binding(
                    get: { colorSchemeContrast == .increased },
                    set: { colorSchemeContrast = $0 ? .increased : .standard }
                ))
                
                Toggle("VoiceOver Mode", isOn: $accessibilityEnabled)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            
            // Content
            content
                .environment(\.sizeCategory, sizeCategory)
                .overlay(
                    accessibilityEnabled ? 
                    Text("VoiceOver Active")
                        .padding(8)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding()
                    : nil,
                    alignment: .topTrailing
                )
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    AccessibilityPreview(content: 
        VStack(spacing: 20) {
            AccessibleEmptyStateView(
                title: "No Lessons",
                message: "Start recording your first lesson",
                systemImage: "mic.fill",
                action: {},
                actionLabel: "Record Lesson"
            )
            
            AccessibleProgressView(
                value: 65,
                total: 100,
                label: "Upload Progress"
            )
            
            AccessibleLoadingView(message: "Processing your lesson")
        }
        .padding()
    )
} 