// Standard library
import Foundation
// Third-party dependencies
import GRPCCore
// Apple frameworks
import OSLog

/// Interceptor that logs gRPC requests and responses
struct LoggingInterceptor: ClientInterceptor, Sendable {
    
    // MARK: - Properties
    let logLevel: LogLevel
    private let logger: OSLog
    
    // MARK: - Initialization
    init(logLevel: LogLevel = .basic, logger: OSLog = OSLog.grpc) {
        self.logLevel = logLevel
        self.logger = logger
    }
    
    // MARK: - ClientInterceptor Implementation
    @Sendable
    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: @Sendable (
            StreamingClientRequest<Input>,
            ClientContext
        ) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        let startTime = Date()
        let requestID = UUID().uuidString
        
        // Log request
        logRequest(context: context, requestID: requestID)
        
        do {
            // Call the next interceptor/handler
            let response = try await next(request, context)
            
            // Log successful response
            let duration = Date().timeIntervalSince(startTime)
            logResponse(
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
    private func logRequest(context: ClientContext, requestID: String) {
        switch logLevel {
        case .none:
            return
            
        case .basic:
            logger.info("gRPC Request [\(requestID)]")
            
        case .detailed:
            let logMessage = "gRPC Request [\(requestID)]"
            logger.info("\(logMessage)")
        }
    }
    
    private func logResponse(
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
                logger.error("gRPC Response [\(requestID)] Failed (\(formatDuration(duration))): \(error?.localizedDescription ?? "Unknown error")")
            }
            
        case .detailed:
            var logMessage = "gRPC Response [\(requestID)]\n"
            logMessage += "  Duration: \(formatDuration(duration))\n"
            logMessage += "  Status: \(success ? "Success" : "Failed")"
            
            if let error = error {
                logMessage += "\n  Error: \(error)"
                if let rpcError = error as? RPCError {
                    logMessage += "\n  Code: \(rpcError.code)"
                    logMessage += "\n  Message: \(rpcError.message)"
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

// MARK: - Request/Response Logging Extensions
// Note: ClientContext in grpc-swift-2 doesn't expose service/method information directly
