// 1. Standard library
import Foundation

// 2. Apple frameworks
import UserNotifications
import UIKit
import OSLog

// 3. Third-party dependencies
import FirebaseMessaging

/// Service for managing push notifications
@MainActor
final class PushNotificationService: NSObject {
    // MARK: - Properties
    
    static let shared = PushNotificationService()
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var fcmToken: String?
    @Published private(set) var apnsToken: Data?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var notificationHandlers: [String: (UNNotificationContent) -> Void] = [:]
    
    // Notification categories
    enum NotificationCategory: String {
        case lessonReminder = "LESSON_REMINDER"
        case transcriptionComplete = "TRANSCRIPTION_COMPLETE"
        case studyReminder = "STUDY_REMINDER"
        case achievement = "ACHIEVEMENT"
    }
    
    // Notification actions
    enum NotificationAction: String {
        case viewLesson = "VIEW_LESSON"
        case dismissReminder = "DISMISS_REMINDER"
        case snoozeReminder = "SNOOZE_REMINDER"
        case shareTranscript = "SHARE_TRANSCRIPT"
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupNotificationCategories()
    }
    
    // MARK: - Public Methods
    
    /// Configure push notifications
    func configure() {
        OSLog.notifications.functionEntry("PushNotificationService.configure")
        
        // Set delegates
        notificationCenter.delegate = self
        Messaging.messaging().delegate = self
        
        // Register for remote notifications
        UIApplication.shared.registerForRemoteNotifications()
        
        // Check current authorization status
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        OSLog.notifications.functionEntry("requestAuthorization")
        
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .providesAppNotificationSettings]
            )
            
            isAuthorized = granted
            
            if granted {
                OSLog.notifications.info("Notification permission granted")
                
                // Register for remote notifications on main thread
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                OSLog.notifications.info("Notification permission denied")
            }
            
            return granted
        } catch {
            OSLog.notifications.error("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    /// Schedule a local notification
    func scheduleNotification(
        title: String,
        body: String,
        date: Date,
        identifier: String,
        category: NotificationCategory? = nil,
        userInfo: [String: Any] = [:]
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        if let category = category {
            content.categoryIdentifier = category.rawValue
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        OSLog.notifications.info("Scheduled notification", metadata: [
            "identifier": identifier,
            "date": date.ISO8601Format()
        ])
    }
    
    /// Schedule a lesson reminder
    func scheduleLessonReminder(
        lesson: Lesson,
        reminderDate: Date
    ) async throws {
        let userInfo: [String: Any] = [
            "lessonId": lesson.id.uuidString,
            "type": "lessonReminder"
        ]
        
        try await scheduleNotification(
            title: "Lesson Reminder",
            body: "Time for your lesson: \(lesson.title)",
            date: reminderDate,
            identifier: "lesson_\(lesson.id.uuidString)",
            category: .lessonReminder,
            userInfo: userInfo
        )
    }
    
    /// Cancel a scheduled notification
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        OSLog.notifications.debug("Cancelled notification", metadata: [
            "identifier": identifier
        ])
    }
    
    /// Cancel all notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        OSLog.notifications.info("Cancelled all pending notifications")
    }
    
    /// Get pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    /// Update badge count
    func updateBadgeCount(_ count: Int) {
        Task { @MainActor in
            // Use the modern API for iOS 17+
            if #available(iOS 17.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(count) { error in
                    if let error = error {
                        OSLog.notifications.error("Failed to update badge count: \(error)")
                    }
                }
            } else {
                // Fallback for older iOS versions
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }
    
    /// Register handler for notification type
    func registerHandler(
        for type: String,
        handler: @escaping (UNNotificationContent) -> Void
    ) {
        notificationHandlers[type] = handler
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationCategories() {
        // Lesson reminder category
        let viewAction = UNNotificationAction(
            identifier: NotificationAction.viewLesson.rawValue,
            title: "View Lesson",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: NotificationAction.dismissReminder.rawValue,
            title: "Dismiss",
            options: [.destructive]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snoozeReminder.rawValue,
            title: "Snooze 10 min",
            options: []
        )
        
        let lessonCategory = UNNotificationCategory(
            identifier: NotificationCategory.lessonReminder.rawValue,
            actions: [viewAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Transcription complete category
        let shareAction = UNNotificationAction(
            identifier: NotificationAction.shareTranscript.rawValue,
            title: "Share",
            options: [.foreground]
        )
        
        let transcriptionCategory = UNNotificationCategory(
            identifier: NotificationCategory.transcriptionComplete.rawValue,
            actions: [viewAction, shareAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Set categories
        notificationCenter.setNotificationCategories([
            lessonCategory,
            transcriptionCategory
        ])
    }
    
    private func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
        
        OSLog.notifications.debug("Notification authorization status", metadata: [
            "status": "\(settings.authorizationStatus.rawValue)"
        ])
    }
    
    private func handleNotificationAction(
        _ action: NotificationAction,
        content: UNNotificationContent
    ) {
        switch action {
        case .viewLesson:
            if let lessonId = content.userInfo["lessonId"] as? String {
                // Post notification to navigate to lesson
                NotificationCenter.default.post(
                    name: .navigateToLesson,
                    object: nil,
                    userInfo: ["lessonId": lessonId]
                )
            }
            
        case .snoozeReminder:
            // Reschedule notification for 10 minutes later
            Task {
                let snoozeDate = Date().addingTimeInterval(600) // 10 minutes
                
                // Convert userInfo to [String: Any]
                let userInfo = content.userInfo as? [String: Any] ?? [:]
                
                try? await scheduleNotification(
                    title: content.title,
                    body: content.body,
                    date: snoozeDate,
                    identifier: UUID().uuidString,
                    category: .lessonReminder,
                    userInfo: userInfo
                )
            }
            
        case .shareTranscript:
            if let lessonId = content.userInfo["lessonId"] as? String {
                NotificationCenter.default.post(
                    name: .shareLesson,
                    object: nil,
                    userInfo: ["lessonId": lessonId]
                )
            }
            
        case .dismissReminder:
            // Just dismiss, no action needed
            break
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content
        
        Task { @MainActor in
            // Handle notification action
            if let action = NotificationAction(rawValue: response.actionIdentifier) {
                handleNotificationAction(action, content: content)
            } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                // Handle tap on notification
                if let type = content.userInfo["type"] as? String,
                   let handler = notificationHandlers[type] {
                    handler(content)
                }
            }
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension PushNotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            self.fcmToken = fcmToken
            
            OSLog.notifications.info("FCM token received", metadata: [
                "tokenPrefix": String(fcmToken?.prefix(10) ?? "")
            ])
            
            // Send token to backend
            if let token = fcmToken {
                Task {
                    await sendTokenToBackend(token)
                }
            }
        }
    }
    
    private func sendTokenToBackend(_ token: String) async {
        // Send FCM token to backend for push notifications
        // Implementation depends on backend API
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToLesson = Notification.Name("navigateToLesson")
    static let shareLesson = Notification.Name("shareLesson")
}

// MARK: - APNS Token Handling

extension PushNotificationService {
    func setAPNSToken(_ deviceToken: Data) {
        self.apnsToken = deviceToken
        
        // Convert to string for logging
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        OSLog.notifications.info("APNS token received", metadata: [
            "tokenPrefix": String(tokenString.prefix(20))
        ])
        
        // Set APNS token for Firebase
        Messaging.messaging().apnsToken = deviceToken
    }
}

// MARK: - Error Types

enum NotificationError: LocalizedError {
    case notAuthorized
    case invalidDate
    case schedulingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notification permissions not granted"
        case .invalidDate:
            return "Invalid notification date"
        case .schedulingFailed:
            return "Failed to schedule notification"
        }
    }
}

 