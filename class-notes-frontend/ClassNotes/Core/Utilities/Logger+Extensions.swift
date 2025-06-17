//
//  Logger+Extensions.swift
//  class-notes-frontend
//
//  Logging infrastructure for better debugging in Cursor
//

import OSLog
import os

extension OSLog {
    // MARK: - Subsystem
    /// Main subsystem for all app logging
    private static let subsystem = "com.classnotes.app"
    
    // MARK: - Feature Loggers
    /// Logger for authentication-related events
    static let authentication = OSLog(subsystem: subsystem, category: "Authentication")
    
    /// Logger for lesson management
    static let lessons = OSLog(subsystem: subsystem, category: "Lessons")
    
    /// Logger for networking and API calls
    static let networking = OSLog(subsystem: subsystem, category: "Networking")
    
    /// Logger for storage operations (Core Data, files)
    static let storage = OSLog(subsystem: subsystem, category: "Storage")
    
    /// Logger for UI events and interactions
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    
    /// Logger for audio recording and transcription
    static let audio = OSLog(subsystem: subsystem, category: "Audio")
    
    /// Logger for gRPC communication
    static let grpc = OSLog(subsystem: subsystem, category: "gRPC")
    
    /// Debug logger for development
    static let debug = OSLog(subsystem: subsystem, category: "Debug")
    
    /// Logger for security-related events
    static let security = OSLog(subsystem: subsystem, category: "Security")
    
    /// Logger for subscription and in-app purchase events
    static let subscription = OSLog(subsystem: subsystem, category: "Subscription")
    
    /// Logger for persistence operations (Core Data, encryption)
    static let persistence = OSLog(subsystem: subsystem, category: "Persistence")
    
    /// Logger for push notifications
    static let notifications = OSLog(subsystem: subsystem, category: "Notifications")
}

// MARK: - Convenience Extensions
extension OSLog {
    /// Log a debug message
    func debug(_ message: String, metadata: [String: String]? = nil) {
        if let metadata = metadata {
            os_log(.debug, log: self, "%{public}@ | %{public}@", message, metadata.description)
        } else {
            os_log(.debug, log: self, "%{public}@", message)
        }
    }
    
    /// Log an info message
    func info(_ message: String, metadata: [String: String]? = nil) {
        if let metadata = metadata {
            os_log(.info, log: self, "%{public}@ | %{public}@", message, metadata.description)
        } else {
            os_log(.info, log: self, "%{public}@", message)
        }
    }
    
    /// Log a warning message
    func warning(_ message: String, metadata: [String: String]? = nil) {
        if let metadata = metadata {
            os_log(.default, log: self, "⚠️ %{public}@ | %{public}@", message, metadata.description)
        } else {
            os_log(.default, log: self, "⚠️ %{public}@", message)
        }
    }
    
    /// Log an error message
    func error(_ message: String, metadata: [String: String]? = nil) {
        if let metadata = metadata {
            os_log(.error, log: self, "❌ %{public}@ | %{public}@", message, metadata.description)
        } else {
            os_log(.error, log: self, "❌ %{public}@", message)
        }
    }
    
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
        self.info(message)
    }
    
    /// Log a network response
    func networkResponse(_ statusCode: Int, url: String, duration: TimeInterval? = nil) {
        var message = "📥 \(statusCode) \(url)"
        if let duration = duration {
            message += " | \(String(format: "%.2fms", duration * 1000))"
        }
        
        switch statusCode {
        case 200..<300:
            self.info(message)
        case 400..<500:
            self.warning(message)
        default:
            self.error(message)
        }
    }
}

// MARK: - Debug Mode Helpers
#if DEBUG
extension OSLog {
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
 OSLog.authentication.info("User signed in successfully")
 OSLog.authentication.error("Sign-in failed: \(error)")
 
 // Network logging
 OSLog.networking.networkRequest("GET", url: "https://api.classnotes.com/lessons")
 OSLog.networking.networkResponse(200, url: "https://api.classnotes.com/lessons", duration: 0.234)
 
 // Function tracing
 OSLog.lessons.functionEntry("loadLessons", parameters: "userId: \(userId)")
 OSLog.lessons.functionExit("loadLessons", result: "count: \(lessons.count)")
 
 // Debug milestones
 OSLog.debug.milestone("App launched")
 
 // Performance tracking
 OSLog.storage.performance("Core Data fetch", duration: 0.045)
 */ 