import Foundation
import Security

protocol KeychainServiceProtocol {
    func save(_ data: Data, for key: String) -> Bool
    func load(key: String) -> Data?
    func delete(key: String) -> Bool
    func saveString(_ string: String, for key: String) -> Bool
    func loadString(key: String) -> String?

    // Apple Sign In specific methods
    func saveAppleUserData(
        userID: String, email: String?, fullName: PersonNameComponents?, identityToken: String?)
    func loadAppleUserData() -> (
        userID: String?, email: String?, fullName: PersonNameComponents?, identityToken: String?
    )
    func clearAppleUserData()
}

final class KeychainService: KeychainServiceProtocol {
    static let shared = KeychainService()

    private let serviceName = "com.classnotes.app"

    private init() {}

    // MARK: - Public Methods

    func save(_ data: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            return dataTypeRef as? Data
        }

        return nil
    }

    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    // MARK: - Convenience Methods

    func saveString(_ string: String, for key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, for: key)
    }

    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Apple Sign In Methods

    func saveAppleUserData(
        userID: String, email: String?, fullName: PersonNameComponents?, identityToken: String?
    ) {
        _ = saveString(userID, for: Key.appleUserID)

        if let email = email {
            _ = saveString(email, for: Key.appleEmail)
        }

        if let fullName = fullName {
            let fullNameData = [
                "givenName": fullName.givenName,
                "familyName": fullName.familyName,
                "middleName": fullName.middleName,
                "namePrefix": fullName.namePrefix,
                "nameSuffix": fullName.nameSuffix,
                "nickname": fullName.nickname,
            ]

            if let data = try? JSONSerialization.data(withJSONObject: fullNameData) {
                _ = save(data, for: Key.appleFullName)
            }
        }

        if let identityToken = identityToken {
            _ = saveString(identityToken, for: Key.appleIdentityToken)
        }
    }

    func loadAppleUserData() -> (
        userID: String?, email: String?, fullName: PersonNameComponents?, identityToken: String?
    ) {
        let userID = loadString(key: Key.appleUserID)
        let email = loadString(key: Key.appleEmail)
        let identityToken = loadString(key: Key.appleIdentityToken)

        var fullName: PersonNameComponents?
        if let data = load(key: Key.appleFullName),
            let fullNameDict = try? JSONSerialization.jsonObject(with: data) as? [String: String?]
        {
            fullName = PersonNameComponents()
            fullName?.givenName = fullNameDict["givenName"] ?? nil
            fullName?.familyName = fullNameDict["familyName"] ?? nil
            fullName?.middleName = fullNameDict["middleName"] ?? nil
            fullName?.namePrefix = fullNameDict["namePrefix"] ?? nil
            fullName?.nameSuffix = fullNameDict["nameSuffix"] ?? nil
            fullName?.nickname = fullNameDict["nickname"] ?? nil
        }

        return (userID: userID, email: email, fullName: fullName, identityToken: identityToken)
    }

    func clearAppleUserData() {
        _ = delete(key: Key.appleUserID)
        _ = delete(key: Key.appleEmail)
        _ = delete(key: Key.appleFullName)
        _ = delete(key: Key.appleIdentityToken)
    }
}

// MARK: - Keychain Keys

extension KeychainService {
    enum Key {
        static let authToken = "auth_token"
        static let refreshToken = "refresh_token"
        static let userID = "user_id"

        // Apple Sign In specific keys
        static let appleUserID = "apple_user_id"
        static let appleEmail = "apple_email"
        static let appleFullName = "apple_full_name"
        static let appleIdentityToken = "apple_identity_token"
    }
}
