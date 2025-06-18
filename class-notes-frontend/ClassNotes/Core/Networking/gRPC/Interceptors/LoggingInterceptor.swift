// Standard library
import Foundation
// Third-party dependencies
import GRPCCore
// Apple frameworks
import OSLog

/// Interceptor that logs gRPC requests and responses
struct LoggingInterceptor: ClientInterceptor, Sendable {
    
    // MARK: - Nested Types
    
    enum LogLevel: Sendable {
        case none
        case basic
        case detailed
    }
    
    // MARK: - Properties
    
    let logLevel: LogLevel
    private let logger: OSLog
    
    // MARK: - Initialization
    
    init(
        logLevel: LogLevel = .basic,
        logger: OSLog = OSLog(subsystem: "com.classnotes", category: "gRPC")
    ) {
        self.logLevel = logLevel
        self.logger = logger
    }
    
    // MARK: - ClientInterceptor Implementation
    
    func intercept<Input: Sendable, Output: Sendable>(
        request: ClientRequest<Input>,
        context: ClientContext,
        next: @Sendable (
            ClientRequest<Input>,
            ClientContext
        ) async throws -> ClientResponse<Output>
    ) async throws -> ClientResponse<Output> {
        let startTime = Date()
        let requestID = UUID().uuidString
        
        // Log request
        logRequest(
            request: request,
            context: context,
            requestID: requestID
        )
        
        do {
            // Call the next interceptor/handler
            let response = try await next(request, context)
            
            // Log successful response
            let duration = Date().timeIntervalSince(startTime)
            logResponse(
                response: response,
                context: context,
                requestID: requestID,
                duration: duration,
                success: true
            )
            
            return response
        } catch {
            // Log error response
            let duration = Date().timeIntervalSince(startTime)
            logResponse(
                response: nil as ClientResponse<Output>?,
                context: context,
                requestID: requestID,
                duration: duration,
                success: false,
                error: error
            )
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func logRequest<Input>(
        request: ClientRequest<Input>,
        context: ClientContext,
        requestID: String
    ) {
        switch logLevel {
        case .none:
            return
            
        case .basic:
            logger.info("gRPC Request [\(requestID)] \(context.descriptor.fullyQualifiedMethod)")
            
        case .detailed:
            var logMessage = "gRPC Request [\(requestID)]\n"
            logMessage += "  Method: \(context.descriptor.fullyQualifiedMethod)\n"
            logMessage += "  Service: \(context.descriptor.fullyQualifiedService)\n"
            
            // Log metadata if present
            if !request.metadata.isEmpty {
                logMessage += "  Headers: \(request.metadata.count) headers"
                #if DEBUG
                // In debug builds, show actual headers (excluding sensitive ones)
                for (key, values) in request.metadata {
                    if !key.lowercased().contains("authorization") && !key.lowercased().contains("token") {
                        // Join multiple values with comma
                        let valueString = values.joined(separator: ", ")
                        logMessage += "\n    \(key): \(valueString)"
                    }
                }
                #endif
            }
            
            logger.info("\(logMessage)")
        }
    }
    
    private func logResponse<Output>(
        response: ClientResponse<Output>?,
        context: ClientContext,
        requestID: String,
        duration: TimeInterval,
        success: Bool,
        error: Error? = nil
    ) {
        switch logLevel {
        case .none:
            return
            
        case .basic:
            if success {
                logger.info("gRPC Response [\(requestID)] Success (\(formatDuration(duration)))")
            } else {
                logger.error(
                    "gRPC Response [\(requestID)] Failed (\(formatDuration(duration))): \(error?.localizedDescription ?? "Unknown error")"
                )
            }
            
        case .detailed:
            var logMessage = "gRPC Response [\(requestID)]\n"
            logMessage += "  Method: \(context.descriptor.fullyQualifiedMethod)\n"
            logMessage += "  Duration: \(formatDuration(duration))\n"
            logMessage += "  Status: \(success ? "Success" : "Failed")"
            
            if let response = response, !response.metadata.isEmpty {
                logMessage += "\n  Response Headers: \(response.metadata.count) headers"
            }
            
            if let error = error {
                logMessage += "\n  Error: \(error)"
                if let rpcError = error as? RPCError {
                    logMessage += "\n  Code: \(rpcError.code)"
                    logMessage += "\n  Message: \(rpcError.message)"
                    if !rpcError.metadata.isEmpty {
                        logMessage += "\n  Error Metadata: \(rpcError.metadata.count) entries"
                    }
                }
            }
            
            if success {
                logger.info("\(logMessage)")
            } else {
                logger.error("\(logMessage)")
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 0.001 {
            return String(format: "%.0fµs", duration * 1_000_000)
        } else if duration < 1.0 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.2fs", duration)
        }
    }
}

// MARK: - OSLog Extension

extension OSLog {
    /// Dedicated logger for gRPC operations
    static let grpc = OSLog(
        subsystem: "com.classnotes",
        category: "gRPC"
    )
}

// MARK: - Request/Response Logging Extensions
// Note: ClientContext in grpc-swift-2 doesn't expose service/method information directly
