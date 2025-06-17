import GoogleSignIn
import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

/// Implementation of Google Sign-In service
@MainActor
final class GoogleSignInService: NSObject, ObservableObject, GoogleSignInServiceProtocol {
    @Published private(set) var isSigningIn = false
    @Published private(set) var error: Error?

    private let keychainService: KeychainServiceProtocol

    init(keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.keychainService = keychainService
        super.init()
    }

    // MARK: - GoogleSignInServiceProtocol

    func signIn() async throws -> GoogleUser {
        #if os(iOS)
            guard let presentingViewController = getRootViewController() else {
                throw AppError.authentication("No presenting view controller available")
            }

            return try await withCheckedThrowingContinuation { continuation in
                isSigningIn = true
                error = nil

                GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) {
                    [weak self] result, error in
                    defer { self?.isSigningIn = false }

                    if let error = error {
                        self?.error = error
                        continuation.resume(
                            throwing: AppError.authentication(error.localizedDescription))
                        return
                    }

                    guard let result = result else {
                        let error = AppError.authentication("No result from Google Sign-In")
                        self?.error = error
                        continuation.resume(throwing: error)
                        return
                    }

                    let googleUser =
                        self?.convertToGoogleUser(result.user)
                        ?? GoogleUser(
                            id: "",
                            email: "",
                            displayName: "",
                            profileImageURL: nil,
                            idToken: nil,
                            accessToken: nil
                        )

                    continuation.resume(returning: googleUser)
                }
            }
        #elseif os(macOS)
            guard let presentingWindow = NSApplication.shared.keyWindow else {
                throw AppError.authentication("No presenting window available")
            }

            return try await withCheckedThrowingContinuation { continuation in
                isSigningIn = true
                error = nil

                GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow) {
                    [weak self] result, error in
                    defer { self?.isSigningIn = false }

                    if let error = error {
                        self?.error = error
                        continuation.resume(
                            throwing: AppError.authentication(error.localizedDescription))
                        return
                    }

                    guard let result = result else {
                        let error = AppError.authentication("No result from Google Sign-In")
                        self?.error = error
                        continuation.resume(throwing: error)
                        return
                    }

                    let googleUser =
                        self?.convertToGoogleUser(result.user)
                        ?? GoogleUser(
                            id: "",
                            email: "",
                            displayName: "",
                            profileImageURL: nil,
                            idToken: nil,
                            accessToken: nil
                        )

                    continuation.resume(returning: googleUser)
                }
            }
        #endif
    }

    func signOut() async {
        await MainActor.run {
            GIDSignIn.sharedInstance.signOut()
            error = nil
        }
    }

    func restorePreviousSignIn() async -> GoogleUser? {
        await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                if let error = error {
                    self?.error = error
                    continuation.resume(returning: nil)
                    return
                }

                if let user = user {
                    let googleUser = self?.convertToGoogleUser(user)
                    continuation.resume(returning: googleUser)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    nonisolated func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Private Methods

    private func convertToGoogleUser(_ gidUser: GIDGoogleUser) -> GoogleUser {
        GoogleUser(
            id: gidUser.userID ?? UUID().uuidString,
            email: gidUser.profile?.email ?? "",
            displayName: gidUser.profile?.name ?? "",
            profileImageURL: gidUser.profile?.imageURL(withDimension: 200),
            idToken: gidUser.idToken?.tokenString,
            accessToken: gidUser.accessToken.tokenString
        )
    }

    #if os(iOS)
        private func getRootViewController() -> UIViewController? {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first
            else {
                return nil
            }
            return window.rootViewController
        }
    #endif
}

/// Mock Google Sign-In service for SwiftUI previews
final class MockGoogleSignInService: GoogleSignInServiceProtocol {
    var isSigningIn = false
    var error: Error?
    var shouldSucceed = true

    func signIn() async throws -> GoogleUser {
        isSigningIn = true
        defer { isSigningIn = false }

        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        if shouldSucceed {
            return GoogleUser(
                id: "123456",
                email: "test@gmail.com",
                displayName: "Test User",
                profileImageURL: URL(string: "https://example.com/photo.jpg"),
                idToken: "mock-id-token",
                accessToken: "mock-access-token"
            )
        } else {
            throw AppError.authentication("Authentication was cancelled")
        }
    }

    func signOut() async {
        // No-op for mock
    }

    func restorePreviousSignIn() async -> GoogleUser? {
        if shouldSucceed {
            return GoogleUser(
                id: "123456",
                email: "test@gmail.com",
                displayName: "Test User",
                profileImageURL: URL(string: "https://example.com/photo.jpg"),
                idToken: "mock-id-token",
                accessToken: "mock-access-token"
            )
        }
        return nil
    }

    nonisolated func handle(_ url: URL) -> Bool {
        true
    }
}
