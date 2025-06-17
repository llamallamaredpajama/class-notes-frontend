import AuthenticationServices
import Foundation
import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

/// Implementation of Apple Sign-In service
@MainActor
final class AppleSignInService: NSObject, ObservableObject, AppleSignInServiceProtocol {
    @Published private(set) var isSigningIn = false
    @Published private(set) var error: Error?

    private let keychainService: KeychainServiceProtocol
    private var signInContinuation: CheckedContinuation<AppleUser, Error>?

    init(keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.keychainService = keychainService
        super.init()
    }

    // MARK: - AppleSignInServiceProtocol

    func signIn() async throws -> AppleUser {
        return try await withCheckedThrowingContinuation { continuation in
            signInContinuation = continuation
            isSigningIn = true
            error = nil

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let authorizationController = ASAuthorizationController(authorizationRequests: [request]
            )
            authorizationController.delegate = self
            #if os(iOS)
                authorizationController.presentationContextProvider = self
            #elseif os(macOS)
                authorizationController.presentationContextProvider = self
            #endif
            authorizationController.performRequests()
        }
    }

    func signOut() async {
        // Apple Sign In doesn't have a sign out method - just clear local state
        await MainActor.run {
            error = nil
        }
    }

    func handleAuthorization(
        userID: String, email: String?, fullName: Foundation.PersonNameComponents?,
        identityToken: Data?
    ) async throws -> AppleUser {
        let identityTokenString = identityToken.flatMap { String(data: $0, encoding: .utf8) }

        // Store Apple user data in keychain using new helper method
        keychainService.saveAppleUserData(
            userID: userID,
            email: email,
            fullName: fullName,
            identityToken: identityTokenString
        )

        return AppleUser(
            id: userID,
            email: email ?? loadStoredEmail(for: userID),
            fullName: fullName ?? loadStoredFullName(for: userID),
            identityToken: identityTokenString
        )
    }

    // MARK: - Private Methods

    private func loadStoredEmail(for userID: String) -> String? {
        let userData = keychainService.loadAppleUserData()
        return userData.email
    }

    private func loadStoredFullName(for userID: String) -> Foundation.PersonNameComponents? {
        let userData = keychainService.loadAppleUserData()
        return userData.fullName
    }

    /// Check for existing Apple Sign In session
    func checkExistingSession() async -> AppleUser? {
        let userData = keychainService.loadAppleUserData()

        guard let userID = userData.userID else {
            return nil
        }

        // Check if the Apple ID credential is still valid
        let appleIDProvider = ASAuthorizationAppleIDProvider()

        do {
            let credentialState = try await appleIDProvider.credentialState(forUserID: userID)

            switch credentialState {
            case .authorized:
                // User is still authorized, return stored user data
                return AppleUser(
                    id: userID,
                    email: userData.email,
                    fullName: userData.fullName,
                    identityToken: userData.identityToken
                )
            case .revoked, .notFound:
                // Clear stored data if authorization is revoked
                keychainService.clearAppleUserData()
                return nil
            case .transferred:
                // Handle transferred credentials if needed
                return nil
            @unknown default:
                return nil
            }
        } catch {
            print("Error checking Apple ID credential state: \(error)")
            return nil
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        defer { isSigningIn = false }

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
        else {
            let error = AppError.authentication("Invalid credential type")
            self.error = error
            signInContinuation?.resume(throwing: error)
            signInContinuation = nil
            return
        }

        Task {
            do {
                let appleUser = try await handleAuthorization(
                    userID: appleIDCredential.user,
                    email: appleIDCredential.email,
                    fullName: appleIDCredential.fullName,
                    identityToken: appleIDCredential.identityToken
                )
                signInContinuation?.resume(returning: appleUser)
            } catch {
                self.error = error
                signInContinuation?.resume(throwing: error)
            }
            signInContinuation = nil
        }
    }

    func authorizationController(
        controller: ASAuthorizationController, didCompleteWithError error: Error
    ) {
        defer {
            isSigningIn = false
            signInContinuation = nil
        }

        if let authError = error as? ASAuthorizationError {
            let authenticationError = mapAuthorizationError(authError)
            self.error = authenticationError
            signInContinuation?.resume(throwing: authenticationError)
        } else {
            self.error = error
            signInContinuation?.resume(throwing: error)
        }
    }

    private func mapAuthorizationError(_ error: ASAuthorizationError) -> Error {
        let errorCode = error.code
        switch errorCode {
        case .canceled:
            return AppError.authentication("User cancelled")
        case .failed:
            return AppError.authentication("Authentication failed")
        case .invalidResponse:
            return AppError.authentication("Invalid response")
        case .notHandled:
            return AppError.authentication("Not handled")
        case .unknown:
            return AppError.authentication("Unknown error")
        case .notInteractive:
            return AppError.authentication("Not interactive")
        case .matchedExcludedCredential:
            return AppError.authentication("Matched excluded credential")
        default:
            return AppError.authentication("Unknown authorization error")
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

#if os(iOS)
    extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first
            else {
                return UIWindow()
            }
            return window
        }
    }
#elseif os(macOS)
    extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            return NSApplication.shared.keyWindow ?? NSWindow()
        }
    }
#endif

/// Mock Apple Sign-In service for SwiftUI previews
final class MockAppleSignInService: AppleSignInServiceProtocol {
    var isSigningIn = false
    var error: Error?
    var shouldSucceed = true

    func signIn() async throws -> AppleUser {
        isSigningIn = true
        defer { isSigningIn = false }

        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        if shouldSucceed {
            var fullName = Foundation.PersonNameComponents()
            fullName.givenName = "Test"
            fullName.familyName = "User"

            return AppleUser(
                id: "001234.567890",
                email: "test@icloud.com",
                fullName: fullName,
                identityToken: "mock-identity-token"
            )
        } else {
            throw AppError.authentication("Authentication was cancelled")
        }
    }

    func signOut() async {
        // No-op for mock
    }

    func handleAuthorization(
        userID: String, email: String?, fullName: Foundation.PersonNameComponents?,
        identityToken: Data?
    ) async throws -> AppleUser {
        return AppleUser(
            id: userID,
            email: email,
            fullName: fullName,
            identityToken: identityToken.flatMap { String(data: $0, encoding: .utf8) }
        )
    }
}
