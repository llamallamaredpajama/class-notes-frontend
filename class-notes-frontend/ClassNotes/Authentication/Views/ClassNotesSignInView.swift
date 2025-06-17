import AuthenticationServices
import SwiftUI

/// Sign-in view for Class Notes app
struct ClassNotesSignInView: View {
    // MARK: - Properties
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var viewModel: AuthenticationViewModel

    private var dynamicSpacing: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 30
        case .large, .xLarge:
            return 35
        case .xxLarge, .xxxLarge:
            return 40
        default:
            return 45
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Using environment object, no initialization needed
    }

    // MARK: - Body
    
    var body: some View {
        ZStack {
            backgroundView
                .ignoresSafeArea()

            contentView
        }
        .alert("Authentication Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Views
    
    private var contentView: some View {
        VStack(spacing: dynamicSpacing) {
            Spacer()

            logoSection
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Class Notes")
                .accessibilityAddTraits(.isHeader)

            taglineView

            Spacer()

            signInSection
                .padding(.horizontal, 32)

            if viewModel.showError, let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            }

            Spacer()
                .frame(height: 50)
        }
        .padding()
    }

    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.95, green: 0.95, blue: 1.0),
                Color(red: 0.85, green: 0.85, blue: 0.95),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(backgroundCircles)
    }
    
    private var backgroundCircles: some View {
        GeometryReader { geometry in
            ForEach(0..<5) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.3),
                                Color.purple.opacity(0.2),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 100...300))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .blur(radius: 50)
                    .animation(
                        reduceMotion
                            ? .none
                            : .easeInOut(duration: Double.random(in: 10...20))
                                .repeatForever(autoreverses: true),
                        value: index
                    )
            }
        }
    }

    private var logoSection: some View {
        VStack(spacing: dynamicSpacing / 2) {
            Text("Class")
                .font(.system(size: scaledFontSize(72), weight: .black, design: .rounded))
                .foregroundColor(.primary)
                .dynamicTypeSize(.large ... .accessibility5)

            HStack(spacing: 10) {
                Image(systemName: "note.text")
                    .font(.system(size: scaledFontSize(60)))
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                Text("Notes")
                    .font(.system(size: scaledFontSize(72), weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .dynamicTypeSize(.large ... .accessibility5)
            }
        }
        .scaleEffect(reduceMotion ? 1.0 : 0.9)
        .animation(
            reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8),
            value: viewModel.isLoading
        )
    }

    private var taglineView: some View {
        VStack(spacing: 8) {
            Text("Your AI-Powered Learning Companion")
                .font(.system(.title2, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(.large ... .accessibility3)
                .accessibilityLabel("Your AI-Powered Learning Companion")

            Text("Take smarter notes, learn faster")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary.opacity(0.8))
                .dynamicTypeSize(.large ... .accessibility3)
                .accessibilityLabel("Take smarter notes, learn faster")
        }
        .padding(.top, 20)
    }

    private var signInSection: some View {
        VStack(spacing: 16) {
            appleSignInButton
            signInDivider
            googleSignInButton
        }
        .overlay(loadingOverlay)
    }
    
    private var appleSignInButton: some View {
        AppleSignInButton {
            viewModel.signInWithApple()
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
        .accessibilityLabel("Sign in with Apple")
        .accessibilityHint("Double tap to sign in using your Apple ID")
        .accessibilityIdentifier("signIn_appleButton")
        .accessibilityAddTraits(viewModel.isLoading ? [.isButton, .isStaticText] : .isButton)
        .accessibilityValue(viewModel.isLoading ? "Loading" : "Ready")
    }
    
    private var signInDivider: some View {
        HStack {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)

            Text("or")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
    
    private var googleSignInButton: some View {
        GoogleSignInButton {
            viewModel.signInWithGoogle()
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
        .accessibilityLabel("Sign in with Google")
        .accessibilityHint("Double tap to sign in using your Google account")
        .accessibilityIdentifier("signIn_googleButton")
        .accessibilityAddTraits(viewModel.isLoading ? [.isButton, .isStaticText] : .isButton)
        .accessibilityValue(viewModel.isLoading ? "Loading" : "Ready")
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(0.8)
        }
    }

    private func errorView(message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, 8)
            .accessibilityLabel("Error: \(message)")
            .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Methods

    private func scaledFontSize(_ baseSize: CGFloat) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall:
            return baseSize * 0.8
        case .small:
            return baseSize * 0.85
        case .medium:
            return baseSize * 0.9
        case .large:
            return baseSize
        case .xLarge:
            return baseSize * 1.1
        case .xxLarge:
            return baseSize * 1.2
        case .xxxLarge:
            return baseSize * 1.3
        case .accessibility1:
            return baseSize * 1.4
        case .accessibility2:
            return baseSize * 1.5
        case .accessibility3:
            return baseSize * 1.6
        case .accessibility4:
            return baseSize * 1.7
        case .accessibility5:
            return baseSize * 1.8
        @unknown default:
            return baseSize
        }
    }
}

// MARK: - Supporting Views

/// Apple Sign In Button
struct AppleSignInButton: View {
    // MARK: - Properties
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    let action: () -> Void

    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "applelogo")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .accessibilityHidden(true)

                Text("Sign in with Apple")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .dynamicTypeSize(.large ... .accessibility3)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.white : Color.black)
            )
        }
        .buttonStyle(ScaledButtonStyle())
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

/// Google Sign-In Button
struct GoogleSignInButton: View {
    // MARK: - Properties
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    let action: () -> Void

    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image("google-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)

                Text("Sign in with Google")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .dynamicTypeSize(.large ... .accessibility3)
            }
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(signInButtonBackground)
            .overlay(signInButtonBorder)
        }
        .buttonStyle(ScaledButtonStyle())
        .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    // MARK: - Views
    
    private var signInButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 4,
                x: 0,
                y: 2
            )
    }
    
    private var signInButtonBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    }
}

/// Button style that scales on press
struct ScaledButtonStyle: ButtonStyle {
    // MARK: - Properties
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1.0)
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 0.1),
                value: configuration.isPressed
            )
    }
}

// MARK: - Preview

#if DEBUG
    struct ClassNotesSignInView_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                ClassNotesSignInView()
                    .environmentObject(
                        AuthenticationViewModel(authService: MockAuthenticationService())
                    )
                    .previewDisplayName("Light Mode")

                ClassNotesSignInView()
                    .environmentObject(
                        AuthenticationViewModel(authService: MockAuthenticationService())
                    )
                    .preferredColorScheme(.dark)
                    .previewDisplayName("Dark Mode")

                ClassNotesSignInView()
                    .environmentObject(
                        AuthenticationViewModel(authService: MockAuthenticationService())
                    )
                    .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
                    .previewDisplayName("Large Text")
            }
        }
    }
#endif
