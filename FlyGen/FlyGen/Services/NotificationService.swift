import UserNotifications
import SwiftUI

@MainActor
class NotificationService: ObservableObject {

    // MARK: - Published State

    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Settings (persisted via AppStorage)

    @AppStorage("creditNotificationsEnabled") var creditNotificationsEnabled: Bool = true
    @AppStorage("engagementNotificationsEnabled") var engagementNotificationsEnabled: Bool = true
    @AppStorage("lastActiveDate") private var lastActiveDateTimestamp: Double = Date().timeIntervalSince1970

    // MARK: - Notification Identifiers

    enum NotificationID {
        static let lowCredits = "flygen.notification.lowCredits"
        static let noCredits = "flygen.notification.noCredits"
        static let reengagement2Days = "flygen.notification.reengagement.2days"
        static let reengagement5Days = "flygen.notification.reengagement.5days"
        static let reengagement7Days = "flygen.notification.reengagement.7days"

        static var allReengagement: [String] {
            [reengagement2Days, reengagement5Days, reengagement7Days]
        }

        static var allCredit: [String] {
            [lowCredits, noCredits]
        }
    }

    // MARK: - Constants

    private let lowCreditThreshold = 20
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Permission Handling

    /// Request notification permission from the user
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("NotificationService: Failed to request permission - \(error.localizedDescription)")
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Credit Notifications

    /// Check credits and schedule appropriate notification if needed
    func checkCreditsAndNotify(credits: Int) {
        guard creditNotificationsEnabled && isAuthorized else { return }

        // Cancel any existing credit notifications first
        cancelCreditNotifications()

        if credits == 0 {
            scheduleNoCreditNotification()
        } else if credits <= lowCreditThreshold {
            scheduleLowCreditNotification(credits: credits)
        }
    }

    /// Schedule a notification for low credits
    private func scheduleLowCreditNotification(credits: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Running Low on Credits"
        content.body = "You have \(credits) credits left. Top up to keep creating stunning flyers!"
        content.sound = .default
        content.badge = 1

        // Schedule for 1 hour later (gives user time to finish current session)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)

        let request = UNNotificationRequest(
            identifier: NotificationID.lowCredits,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule low credit notification - \(error.localizedDescription)")
            } else {
                print("NotificationService: Scheduled low credit notification (\(credits) credits)")
            }
        }
    }

    /// Schedule a notification when user has no credits
    private func scheduleNoCreditNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Out of Credits"
        content.body = "You've used all your credits! Get more to continue creating amazing flyers."
        content.sound = .default
        content.badge = 1

        // Schedule for 30 minutes later
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false)

        let request = UNNotificationRequest(
            identifier: NotificationID.noCredits,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule no credit notification - \(error.localizedDescription)")
            } else {
                print("NotificationService: Scheduled no credit notification")
            }
        }
    }

    /// Cancel pending credit notifications
    func cancelCreditNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: NotificationID.allCredit)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: NotificationID.allCredit)
    }

    // MARK: - Re-engagement Notifications

    /// Schedule re-engagement notifications for 2, 5, and 7 days
    func scheduleReengagementNotifications() {
        guard engagementNotificationsEnabled && isAuthorized else { return }

        // Cancel any existing re-engagement notifications
        cancelReengagementNotifications()

        // Schedule notifications
        scheduleReengagementNotification(
            identifier: NotificationID.reengagement2Days,
            title: "Your Flyers Miss You!",
            body: "Haven't created a flyer in a while? Your next event deserves a stunning design!",
            days: 2
        )

        scheduleReengagementNotification(
            identifier: NotificationID.reengagement5Days,
            title: "Time to Create Something Amazing",
            body: "It's been a few days! Come back and design your next eye-catching flyer.",
            days: 5
        )

        scheduleReengagementNotification(
            identifier: NotificationID.reengagement7Days,
            title: "We've Got New Ideas for You",
            body: "A week without a new flyer? Let's fix that! Open FlyGen and get inspired.",
            days: 7
        )
    }

    /// Schedule a single re-engagement notification
    private func scheduleReengagementNotification(identifier: String, title: String, body: String, days: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Calculate time interval for N days
        let timeInterval = TimeInterval(days * 24 * 60 * 60)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule \(days)-day re-engagement - \(error.localizedDescription)")
            } else {
                print("NotificationService: Scheduled \(days)-day re-engagement notification")
            }
        }
    }

    /// Cancel pending re-engagement notifications
    func cancelReengagementNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: NotificationID.allReengagement)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: NotificationID.allReengagement)
    }

    // MARK: - App Lifecycle

    /// Called when app becomes active - cancel re-engagement since user is back
    func appDidBecomeActive() {
        // Update last active date
        lastActiveDateTimestamp = Date().timeIntervalSince1970

        // Cancel re-engagement notifications since user is active
        cancelReengagementNotifications()

        // Clear badge
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }

        // Refresh authorization status
        Task {
            await checkAuthorizationStatus()
        }
    }

    /// Called when app enters background - schedule re-engagement notifications
    func appDidEnterBackground() {
        // Update last active date
        lastActiveDateTimestamp = Date().timeIntervalSince1970

        // Schedule re-engagement notifications
        scheduleReengagementNotifications()
    }

    // MARK: - Settings Helpers

    /// Toggle credit notifications and handle permission if needed
    func setCreditNotificationsEnabled(_ enabled: Bool) async {
        if enabled && !isAuthorized {
            let granted = await requestPermission()
            if !granted {
                creditNotificationsEnabled = false
                return
            }
        }

        creditNotificationsEnabled = enabled

        if !enabled {
            cancelCreditNotifications()
        }
    }

    /// Toggle engagement notifications and handle permission if needed
    func setEngagementNotificationsEnabled(_ enabled: Bool) async {
        if enabled && !isAuthorized {
            let granted = await requestPermission()
            if !granted {
                engagementNotificationsEnabled = false
                return
            }
        }

        engagementNotificationsEnabled = enabled

        if enabled {
            scheduleReengagementNotifications()
        } else {
            cancelReengagementNotifications()
        }
    }
}
