import Foundation
import GeneratedProtos

/// Network errors following cursor rules pattern
enum NetworkError: LocalizedError {
    case offline
    case unauthorized
    case quotaExceeded(message: String)
    case serverError(code: String, message: String)
    case timeout
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection"
        case .unauthorized:
            return "Authentication required"
        case .quotaExceeded(let message):
            return "Quota exceeded: \(message)"
        case .serverError(_, let message):
            return message
        case .timeout:
            return "Request timed out"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .offline:
            return "Please check your internet connection"
        case .unauthorized:
            return "Please sign in again"
        case .quotaExceeded:
            return "Upgrade your plan or wait for quota reset"
        case .serverError(let code, _):
            return "Error code: \(code)"
        case .timeout:
            return "Please try again"
        case .unknown:
            return nil
        }
    }
}

/// Map gRPC errors to user-friendly NetworkError
func mapGRPCError(_ error: Error) -> NetworkError {
    guard let grpcError = error as? RPCError else {
        return .unknown(error)
    }

    switch grpcError.code {
    case .unavailable:
        return .offline
    case .unauthenticated:
        return .unauthorized
    case .resourceExhausted:
        return .quotaExceeded(message: grpcError.message ?? "")
    case .deadlineExceeded:
        return .timeout
    default:
        return .serverError(
            code: "\(grpcError.code)",
            message: grpcError.message ?? "Unknown error"
        )
    }
}
