// 1. Standard library
import Foundation

// 2. Apple frameworks
import CryptoKit
import Security
import OSLog

/// Service for implementing certificate pinning to prevent MITM attacks
final class CertificatePinningService: NSObject {
    // MARK: - Properties
    
    static let shared = CertificatePinningService()
    
    /// Production server certificate pins (SHA256 of public key)
    /// These should be updated when server certificates are rotated
    private let productionPins = [
        // Primary certificate pin
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",
        // Backup certificate pin
        "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
    ]
    
    /// Certificate pinning configuration
    private let configuration = CertificatePinningConfiguration(
        hosts: ["api.classnotes.app", "classnotes-api.com"],
        includeSubdomains: true,
        enforceInProduction: true,
        allowUserTrust: false,
        validateCertificateChain: true,
        minimumTLSVersion: .TLSv12
    )
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Create a URLSession with certificate pinning enabled
    func createPinnedURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
        return session
    }
    
    /// Validate a server trust against pinned certificates
    func validateServerTrust(
        _ serverTrust: SecTrust,
        host: String
    ) -> Bool {
        // Skip pinning in debug builds unless explicitly enabled
        #if DEBUG
        if !configuration.enforceInDebug {
            os_log("Certificate pinning skipped in debug build", log: OSLog.security, type: .debug)
            return true
        }
        #endif
        
        // Check if host should be pinned
        guard shouldPinHost(host) else {
            os_log("Host not configured for pinning: %@", log: OSLog.security, type: .debug, host)
            return true
        }
        
        // Validate certificate chain if required
        if configuration.validateCertificateChain {
            var error: CFError?
            let isValid = SecTrustEvaluateWithError(serverTrust, &error)
            
            if !isValid {
                os_log("Certificate chain validation failed for host: %@, error: %@", 
                       log: OSLog.security, type: .error, 
                       host, error?.localizedDescription ?? "Unknown error")
                return false
            }
        }
        
        // Extract certificate chain
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              !certificateChain.isEmpty else {
            os_log("Failed to extract certificate chain", log: OSLog.security, type: .error)
            return false
        }
        
        // Check each certificate in the chain
        for certificate in certificateChain {
            if let publicKey = SecCertificateCopyKey(certificate) {
                let publicKeyHash = hashPublicKey(publicKey)
                
                if productionPins.contains(publicKeyHash) {
                    os_log("Certificate pinning validation successful for host: %@, matchedPin: %@", 
                           log: OSLog.security, type: .info, 
                           host, String(publicKeyHash.prefix(10)) + "...")
                    return true
                }
            }
        }
        
        os_log("Certificate pinning validation failed - no matching pins for host: %@, chainLength: %d", 
               log: OSLog.security, type: .error, 
               host, certificateChain.count)
        
        return false
    }
    
    // MARK: - Private Methods
    
    private func shouldPinHost(_ host: String) -> Bool {
        for pinnedHost in configuration.hosts {
            if host == pinnedHost {
                return true
            }
            
            if configuration.includeSubdomains && host.hasSuffix(".\(pinnedHost)") {
                return true
            }
        }
        
        return false
    }
    
    private func hashPublicKey(_ publicKey: SecKey) -> String {
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return ""
        }
        
        // Create SHA256 hash of the public key
        let hash = SHA256.hash(data: publicKeyData)
        return Data(hash).base64EncodedString()
    }
}

// MARK: - URLSessionDelegate

extension CertificatePinningService: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        if validateServerTrust(serverTrust, host: host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Configuration

struct CertificatePinningConfiguration {
    let hosts: [String]
    let includeSubdomains: Bool
    let enforceInProduction: Bool
    let enforceInDebug: Bool = false
    let allowUserTrust: Bool
    let validateCertificateChain: Bool
    let minimumTLSVersion: tls_protocol_version_t
}

// MARK: - Certificate Pinning for gRPC-Swift-2

// Note: In grpc-swift-2, certificate pinning is handled at the transport layer
// through custom TLS configuration. The actual implementation would be done
// when creating the HTTP2ClientTransport with appropriate TLS settings.

  