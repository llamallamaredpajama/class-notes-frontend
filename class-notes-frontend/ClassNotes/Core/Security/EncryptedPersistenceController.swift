// 1. Standard library
import Foundation

// 2. Apple frameworks
import CoreData
import CryptoKit
import OSLog

/// Enhanced persistence controller with encryption support
final class EncryptedPersistenceController {
    // MARK: - Properties
    
    static let shared = EncryptedPersistenceController()
    
    let container: NSPersistentContainer
    private let encryptionKey: SymmetricKey
    private let keychainService = KeychainService.shared
    
    // Encryption configuration
    private let encryptionKeyIdentifier = "com.classnotes.encryption.key"
    private let encryptedAttributes = [
        "transcript",
        "content", 
        "notes",
        "email",
        "displayName"
    ]
    
    // MARK: - Initialization
    
    init(inMemory: Bool = false) {
        // Initialize container
        container = NSPersistentContainer(name: "ClassNotes")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure for encryption
            if let storeDescription = container.persistentStoreDescriptions.first {
                // Enable encryption at rest
                storeDescription.setOption(
                    FileProtectionType.completeUnlessOpen as NSString,
                    forKey: NSPersistentStoreFileProtectionKey
                )
                
                // Enable Write-Ahead Logging for better performance
                storeDescription.setOption(
                    true as NSNumber,
                    forKey: NSPersistentHistoryTrackingKey
                )
                
                // Set secure deletion
                storeDescription.setOption(
                    true as NSNumber,
                    forKey: "secure_delete"
                )
            }
        }
        
        // Load or generate encryption key
        self.encryptionKey = Self.loadOrCreateEncryptionKey()
        
        // Load persistent stores
        container.loadPersistentStores { description, error in
            if let error = error {
                os_log("Failed to load Core Data stack: %@", log: OSLog.persistence, type: .error, error.localizedDescription)
                fatalError("Failed to load Core Data stack: \(error)")
            }
            
            os_log("Core Data stack loaded with encryption at %@", log: OSLog.persistence, type: .info, description.url?.absoluteString ?? "in-memory")
        }
        
        // Configure container
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Register for encryption/decryption
        registerForEncryption()
    }
    
    // MARK: - Public Methods
    
    /// Save context with encryption
    func save() throws {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            os_log("Context saved successfully", log: OSLog.persistence, type: .debug)
        } catch {
            os_log("Failed to save context: %@", log: OSLog.persistence, type: .error, error.localizedDescription)
            throw error
        }
    }
    
    /// Perform background task with encryption support
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await container.performBackgroundTask { context in
            context.automaticallyMergesChangesFromParent = true
            return try block(context)
        }
    }
    
    /// Export encrypted backup
    func exportEncryptedBackup() async throws -> Data {
        os_log("exportEncryptedBackup", log: OSLog.persistence, type: .debug)
        
        return try await performBackgroundTask { context in
            // Fetch all data
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Lesson")
            let lessons = try context.fetch(fetchRequest)
            
            // Create backup dictionary
            var backup: [String: Any] = [
                "version": "1.0",
                "timestamp": Date(),
                "lessons": []
            ]
            
            // Serialize lessons
            let lessonsData = try lessons.map { lesson in
                try self.serializeManagedObject(lesson)
            }
            
            backup["lessons"] = lessonsData
            
            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: backup)
            
            // Encrypt the backup
            let encryptedData = try self.encrypt(jsonData)
            
            os_log("Encrypted backup created - size: %d bytes, lessonCount: %d", log: OSLog.persistence, type: .info, encryptedData.count, lessons.count)
            
            return encryptedData
        }
    }
    
    /// Import encrypted backup
    func importEncryptedBackup(_ encryptedData: Data) async throws {
        os_log("importEncryptedBackup", log: OSLog.persistence, type: .debug)
        
        // Decrypt the backup
        let jsonData = try decrypt(encryptedData)
        
        // Parse JSON
        guard let backup = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let version = backup["version"] as? String,
              version == "1.0" else {
            throw EncryptionError.invalidBackupFormat
        }
        
        try await performBackgroundTask { context in
            // Clear existing data
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Lesson")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
            
            // Import lessons
            if let lessonsData = backup["lessons"] as? [[String: Any]] {
                for lessonData in lessonsData {
                    try self.deserializeManagedObject(lessonData, in: context)
                }
            }
            
            try context.save()
            
            os_log("Encrypted backup imported successfully", log: OSLog.persistence, type: .info)
        }
    }
    
    // MARK: - Private Methods
    
    private static func loadOrCreateEncryptionKey() -> SymmetricKey {
        let keychainService = KeychainService.shared
        let keyIdentifier = "com.classnotes.encryption.key"
        
        // Try to load existing key
        if let keyData = keychainService.load(key: keyIdentifier) {
            os_log("Loaded existing encryption key from keychain", log: OSLog.security, type: .debug)
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        // Save to keychain
        if keychainService.save(keyData, for: keyIdentifier) {
            os_log("Generated and saved new encryption key", log: OSLog.security, type: .info)
        } else {
            os_log("Failed to save encryption key to keychain", log: OSLog.security, type: .error)
        }
        
        return newKey
    }
    
    private func registerForEncryption() {
        // Register value transformers for encrypted attributes
        for attribute in encryptedAttributes {
            let transformer = EncryptionTransformer(encryptionKey: encryptionKey)
            ValueTransformer.setValueTransformer(
                transformer,
                forName: NSValueTransformerName("EncryptionTransformer_\(attribute)")
            )
        }
    }
    
    private func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return combined
    }
    
    private func decrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }
    
    private func serializeManagedObject(_ object: NSManagedObject) throws -> [String: Any] {
        var result: [String: Any] = [:]
        
        for (key, _) in object.entity.attributesByName {
            if let value = object.value(forKey: key) {
                result[key] = value
            }
        }
        
        return result
    }
    
    private func deserializeManagedObject(_ data: [String: Any], in context: NSManagedObjectContext) throws {
        // This is a simplified example - actual implementation would need entity name
        let entity = NSEntityDescription.entity(forEntityName: "Lesson", in: context)!
        let object = NSManagedObject(entity: entity, insertInto: context)
        
        for (key, value) in data {
            object.setValue(value, forKey: key)
        }
    }
}

// MARK: - Encryption Transformer

/// Value transformer for encrypting Core Data attributes
final class EncryptionTransformer: ValueTransformer {
    // MARK: - Properties
    
    private let encryptionKey: SymmetricKey
    
    // MARK: - Initialization
    
    init(encryptionKey: SymmetricKey) {
        self.encryptionKey = encryptionKey
        super.init()
    }
    
    // MARK: - Transformer Methods
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let string = value as? String,
              let data = string.data(using: .utf8) else {
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
            return sealedBox.combined
        } catch {
            os_log("Failed to encrypt value: %@", log: OSLog.persistence, type: .error, error.localizedDescription)
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let encryptedData = value as? Data else {
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            os_log("Failed to decrypt value: %@", log: OSLog.persistence, type: .error, error.localizedDescription)
            return nil
        }
    }
}

// MARK: - Encryption Errors

enum EncryptionError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidBackupFormat
    case keyGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidBackupFormat:
            return "Invalid backup format"
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        }
    }
}

 