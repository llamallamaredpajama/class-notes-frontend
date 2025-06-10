import SwiftUI

/// Sign-in view for Class Notes app
struct ClassNotesSignInView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var viewModel: AuthenticationViewModel
    
    init(authService: AuthenticationServiceProtocol) {
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: authService))
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: dynamicSpacing) {
                Spacer()
                
                // Logo and Title
                logoSection
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Class Notes")
                    .accessibilityAddTraits(.isHeader)
                
                // Tagline
                taglineView
                
                Spacer()
                
                // Sign In Button
                signInButton
                    .padding(.horizontal, 32)
                
                // Error Message
                if viewModel.showError, let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                }
                
                Spacer()
                    .frame(height: 50)
            }
            .padding()
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
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.95, green: 0.95, blue: 1.0),
                Color(red: 0.85, green: 0.85, blue: 0.95)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            GeometryReader { geometry in
                ForEach(0..<5) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.2)
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
                            reduceMotion ? .none : .easeInOut(duration: Double.random(in: 10...20))
                                .repeatForever(autoreverses: true),
                            value: index
                        )
                }
            }
        )
    }
    
    private var logoSection: some View {
        VStack(spacing: dynamicSpacing / 2) {
            // "Class" text
            Text("Class")
                .font(.system(size: scaledFontSize(72), weight: .black, design: .rounded))
                .foregroundColor(.primary)
                .dynamicTypeSize(.large ... .accessibility5)
            
            // "Notes" text with icon
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
    
    private var signInButton: some View {
        GoogleSignInButton {
            viewModel.signInWithGoogle()
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
            }
        )
        .accessibilityLabel("Sign in with Google")
        .accessibilityHint("Double tap to sign in using your Google account")
        .accessibilityIdentifier("signIn_googleButton")
        .accessibilityAddTraits(viewModel.isLoading ? [.isButton, .isStaticText] : .isButton)
        .accessibilityValue(viewModel.isLoading ? "Loading" : "Ready")
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
    
    // MARK: - Helper Properties
    
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

/// Google Sign-In Button
struct GoogleSignInButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    let action: () -> Void
    
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaledButtonStyle())
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

/// Button style that scales on press
struct ScaledButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1.0)
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 0.1),
                value: configuration.isPressed
            )
    }
}

// MARK: - Previews

#if DEBUG
struct ClassNotesSignInView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ClassNotesSignInView(authService: MockAuthenticationService())
                .previewDisplayName("Light Mode")
            
            ClassNotesSignInView(authService: MockAuthenticationService())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            ClassNotesSignInView(authService: MockAuthenticationService())
                .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
                .previewDisplayName("Large Text")
        }
    }
}
#endif 