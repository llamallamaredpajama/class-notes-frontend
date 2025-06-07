import SwiftUI
import AuthenticationServices

// MARK: - Sign In View

struct ClassNotesSignInView: View {
    @StateObject private var viewModel = SignInViewModel()
    @State private var animateGradient = false
    @State private var showContent = false
    @State private var floatingAnimation = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // MARK: - Background
            AnimatedBackgroundView(animateGradient: $animateGradient)
            
            // MARK: - Binary Code Background (behind everything)
            BinaryCodeAnimationView()
                .opacity(0.2)
                .blur(radius: 0.5)
            
            // MARK: - Floating 3D Elements
            FloatingElementsView(floatingAnimation: $floatingAnimation)
                .allowsHitTesting(false)
            
            // MARK: - Main Content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and Title Section
                VStack(spacing: 24) {
                    // 3D Logo
                    Logo3DView()
                        .frame(width: 120, height: 120)
                        .scaleEffect(showContent ? 1 : 0.8)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: showContent)
                    
                    // Big Typography Title
                    VStack(spacing: 8) {
                        Text("Class")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Notes")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "00D4FF"), Color(hex: "0099FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: "00D4FF").opacity(0.5), radius: 20, y: 4)
                    }
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: showContent)
                    
                    // Tagline
                    Text("Transform your learning with AI")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .offset(y: showContent ? 0 : 20)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: showContent)
                }
                .padding(.bottom, 60)
                
                Spacer()
                
                // Sign In Section with Morphism
                MorphismContainer {
                    VStack(spacing: 20) {
                        Text("Get Started")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 16) {
                            // Sign in with Apple
                            SignInWithAppleButton(.signIn) { request in
                                viewModel.handleSignInWithAppleRequest(request)
                            } onCompletion: { result in
                                viewModel.handleSignInWithAppleCompletion(result)
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 56)
                            .cornerRadius(28)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                            
                            // Sign in with Google
                            GoogleSignInButton {
                                viewModel.signInWithGoogle()
                            }
                        }
                        
                        Text("Your data is encrypted and secure")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 8)
                    }
                    .padding(32)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .offset(y: showContent ? 0 : 50)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5), value: showContent)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatingAnimation.toggle()
            }
            showContent = true
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Animated Background

struct AnimatedBackgroundView: View {
    @Binding var animateGradient: Bool
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "0A0A0A"),
                    Color(hex: "1A1A2E"),
                    Color(hex: "16213E")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated gradient overlay
            LinearGradient(
                colors: [
                    Color(hex: "00D4FF").opacity(0.3),
                    Color(hex: "0099FF").opacity(0.2),
                    Color.clear
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .blendMode(.screen)
            
            // Lightning effect
            RadialGradient(
                colors: [
                    Color(hex: "00D4FF").opacity(0.3),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 400
            )
            .offset(y: -200)
            .blur(radius: 40)
        }
    }
}

// MARK: - Floating 3D Elements

struct FloatingElementsView: View {
    @Binding var floatingAnimation: Bool
    
    var body: some View {
        ZStack {
            // Floating orb 1
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "00D4FF").opacity(0.6),
                            Color(hex: "0099FF").opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 20)
                .offset(
                    x: floatingAnimation ? -100 : -80,
                    y: floatingAnimation ? -200 : -180
                )
            
            // Floating orb 2
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FF00D4").opacity(0.4),
                            Color(hex: "9900FF").opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 30)
                .offset(
                    x: floatingAnimation ? 120 : 100,
                    y: floatingAnimation ? 100 : 120
                )
            
            // Floating orb 3
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "00FFD4").opacity(0.5),
                            Color(hex: "00FF99").opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .blur(radius: 15)
                .offset(
                    x: floatingAnimation ? 80 : 60,
                    y: floatingAnimation ? -150 : -130
                )
        }
    }
}

// MARK: - Binary Code Animation

struct BinaryCodeAnimationView: View {
    @State private var animationOffset: CGFloat = 0
    let binaryStrings = [
        "01101100 01100101 01100001 01110010 01101110",
        "01110100 01110010 01100001 01101110 01110011 01100011 01110010 01101001 01100010 01100101",
        "01100001 01101110 01100001 01101100 01111001 01111010 01100101",
        "01110011 01110101 01101101 01101101 01100001 01110010 01101001 01111010 01100101",
        "01101110 01101111 01110100 01100101 01110011",
        "01100011 01101100 01100001 01110011 01110011",
        "01000001 01001001",
        "01110010 01100101 01100011 01101111 01110010 01100100",
        "01110000 01110010 01101111 01100011 01100101 01110011 01110011"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 15) {
                ForEach(0..<9) { row in
                    BinaryCodeRow(
                        text: binaryStrings[row % binaryStrings.count],
                        width: geometry.size.width,
                        delay: Double(row) * 0.3,
                        animationOffset: animationOffset
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: geometry.size.height * 0.15) // Position around the microphone area
        }
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                animationOffset = 1
            }
        }
    }
}

struct BinaryCodeRow: View {
    let text: String
    let width: CGFloat
    let delay: Double
    let animationOffset: CGFloat
    
    var body: some View {
        HStack(spacing: 20) {
            // Create multiple copies of the text for seamless loop
            ForEach(0..<3) { _ in
                Text(text)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(hex: "00D4FF"))
                    .opacity(0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.3), location: 0.15),
                    .init(color: .black.opacity(0.6), location: 0.3),
                    .init(color: .black.opacity(0.6), location: 0.7),
                    .init(color: .black.opacity(0.3), location: 0.85),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width)
        )
        .offset(x: -width + (width * 2 * animationOffset))
        .animation(.linear(duration: 15).repeatForever(autoreverses: false).delay(delay), value: animationOffset)
    }
}

// MARK: - 3D Logo

struct Logo3DView: View {
    @State private var rotation: Double = 0
    @State private var microphonePulse: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Shadow layer
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.black.opacity(0.3))
                .offset(y: 10)
                .blur(radius: 10)
            
            // Main logo container
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1A1A2E"),
                            Color(hex: "16213E")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "00D4FF").opacity(0.5),
                                    Color(hex: "0099FF").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            
            // Microphone Icon with sound waves
            ZStack {
                // Sound wave rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "00D4FF").opacity(0.3 - Double(index) * 0.1),
                                    Color(hex: "0099FF").opacity(0.2 - Double(index) * 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 60 + CGFloat(index) * 20, height: 60 + CGFloat(index) * 20)
                        .scaleEffect(microphonePulse)
                        .opacity(microphonePulse == 1.0 ? 1 : 0)
                        .animation(
                            .easeOut(duration: 2)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: microphonePulse
                        )
                }
                
                // Microphone icon
                Image(systemName: "mic.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "00D4FF"),
                                Color(hex: "0099FF")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: "00D4FF").opacity(0.5), radius: 10)
            }
        }
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                rotation = 20
            }
            withAnimation {
                microphonePulse = 1.5
            }
        }
    }
}

// MARK: - Morphism Container

struct MorphismContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    // Base blur layer
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.ultraThinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.1),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    
                    // Border gradient
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
}

// MARK: - Google Sign In Button

struct GoogleSignInButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image("google-logo") // You'll need to add this to Assets
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 24, height: 24)
                
                Text("Sign in with Google")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(28)
            .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(PressedButtonStyle())
    }
}

// MARK: - Button Style

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Model

@MainActor
class SignInViewModel: ObservableObject {
    @Published var isSigningIn = false
    @Published var error: AuthError?
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return
            }
            
            // Process the Apple ID credential
            Task {
                await processAppleSignIn(credential: appleIDCredential)
            }
            
        case .failure(let error):
            self.error = AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    func signInWithGoogle() {
        Task {
            isSigningIn = true
            defer { isSigningIn = false }
            
            do {
                // Implement Google Sign-In
                // This would integrate with your GoogleSignInService
                print("Google Sign-In initiated")
            } catch {
                self.error = AuthError.signInFailed(error.localizedDescription)
            }
        }
    }
    
    private func processAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        // Process the credential with your authentication service
        print("Processing Apple Sign-In")
        
        // After successful authentication, update AuthenticationManager
        AuthenticationManager.shared.signIn()
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case signInFailed(String)
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    ClassNotesSignInView()
} 