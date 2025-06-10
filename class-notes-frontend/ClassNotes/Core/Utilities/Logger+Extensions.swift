//
//  Logger+Extensions.swift
//  class-notes-frontend
//
//  Logging infrastructure for better debugging in Cursor
//

import OSLog

extension Logger {
    // MARK: - Subsystem
    /// Main subsystem for all app logging
    private static let subsystem = "com.classnotes.app"
    
    // MARK: - Feature Loggers
    /// Logger for authentication-related events
    static let authentication = Logger(subsystem: subsystem, category: "Authentication")
    
    /// Logger for lesson management
    static let lessons = Logger(subsystem: subsystem, category: "Lessons")
    
    /// Logger for networking and API calls
    static let networking = Logger(subsystem: subsystem, category: "Networking")
    
    /// Logger for storage operations (Core Data, files)
    static let storage = Logger(subsystem: subsystem, category: "Storage")
    
    /// Logger for UI events and interactions
    static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// Logger for audio recording and transcription
    static let audio = Logger(subsystem: subsystem, category: "Audio")
    
    /// Logger for gRPC communication
    static let grpc = Logger(subsystem: subsystem, category: "gRPC")
    
    /// Debug logger for development
    static let debug = Logger(subsystem: subsystem, category: "Debug")
}

// MARK: - Convenience Extensions
extension Logger {
    /// Log a function entry point with parameters
    func functionEntry(_ function: String = #function, parameters: String? = nil) {
        if let parameters = parameters {
            self.debug("→ \(function) | \(parameters)")
        } else {
            self.debug("→ \(function)")
        }
    }
    
    /// Log a function exit point with result
    func functionExit(_ function: String = #function, result: String? = nil) {
        if let result = result {
            self.debug("← \(function) | \(result)")
        } else {
            self.debug("← \(function)")
        }
    }
    
    /// Log a network request
    func networkRequest(_ method: String, url: String, headers: [String: String]? = nil) {
        var message = "🌐 \(method) \(url)"
        if let headers = headers, !headers.isEmpty {
            message += " | Headers: \(headers.count)"
        }
        self.info("\(message)")
    }
    
    /// Log a network response
    func networkResponse(_ statusCode: Int, url: String, duration: TimeInterval? = nil) {
        var message = "📥 \(statusCode) \(url)"
        if let duration = duration {
            message += " | \(String(format: "%.2fms", duration * 1000))"
        }
        
        switch statusCode {
        case 200..<300:
            self.info("\(message)")
        case 400..<500:
            self.warning("\(message)")
        default:
            self.error("\(message)")
        }
    }
}

// MARK: - Debug Mode Helpers
#if DEBUG
extension Logger {
    /// Log with visual separator for important events
    func milestone(_ message: String) {
        self.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        self.info("⭐️ \(message)")
        self.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    /// Log performance metrics
    func performance(_ operation: String, duration: TimeInterval) {
        let milliseconds = duration * 1000
        let emoji = milliseconds < 100 ? "🟢" : milliseconds < 500 ? "🟡" : "🔴"
        self.debug("\(emoji) \(operation): \(String(format: "%.2fms", milliseconds))")
    }
}
#endif

// MARK: - Usage Examples
/*
 // Authentication logging
 Logger.authentication.info("User signed in successfully")
 Logger.authentication.error("Sign-in failed: \(error)")
 
 // Network logging
 Logger.networking.networkRequest("GET", url: "https://api.classnotes.com/lessons")
 Logger.networking.networkResponse(200, url: "https://api.classnotes.com/lessons", duration: 0.234)
 
 // Function tracing
 Logger.lessons.functionEntry("loadLessons", parameters: "userId: \(userId)")
 Logger.lessons.functionExit("loadLessons", result: "count: \(lessons.count)")
 
 // Debug milestones
 Logger.debug.milestone("App launched")
 
 // Performance tracking
 Logger.storage.performance("Core Data fetch", duration: 0.045)
 */ 