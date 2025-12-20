import UserNotifications
import SwiftUI

/// Service for managing credit reminder notifications
/// Handles both local system notifications and in-app alerts
@MainActor
class NotificationService: ObservableObject {

    // MARK: - Configuration

    /// Hours to wait before sending reminder after credits hit 0
    private let reminderDelayHours: TimeInterval = 24

    /// Notification identifier for cancellation
    private let creditReminderIdentifier = "com.flygen.creditReminder"

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let creditsHitZeroDate = "notificationService.creditsHitZeroDate"
        static let notificationScheduled = "notificationService.notificationScheduled"
        static let hasShownInAppAlert = "notificationService.hasShownInAppAlert"
        static let notificationPermissionAsked = "notificationService.notificationPermissionAsked"
    }

    // MARK: - Published State

    @Published var shouldShowInAppAlert: Bool = false
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Stored State

    private var creditsHitZeroDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.creditsHitZeroDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.creditsHitZeroDate) }
    }

    private var notificationScheduled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.notificationScheduled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.notificationScheduled) }
    }

    private var hasShownInAppAlert: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasShownInAppAlert) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasShownInAppAlert) }
    }

    private var notificationPermissionAsked: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.notificationPermissionAsked) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.notificationPermissionAsked) }
    }

    // MARK: - Initialization

    init() {
        Task {
            await checkNotificationPermission()
        }
    }

    // MARK: - Public Methods

    /// Call this after credits are deducted to check if credits hit 0
    /// - Parameter newCredits: The current credit count after change
    func onCreditsChanged(newCredits: Int) {
        if newCredits <= 0 {
            handleCreditsHitZero()
        } else {
            handleCreditsRestored()
        }
    }

    /// Call when user returns to the app (foreground)
    /// - Parameter currentCredits: The current credit count
    func onAppBecameActive(currentCredits: Int) {
        if currentCredits <= 0 && !hasShownInAppAlert {
            shouldShowInAppAlert = true
        }

        // Clear badge when app becomes active
        clearBadge()
    }

    /// Call when user dismisses the in-app alert
    func dismissInAppAlert() {
        shouldShowInAppAlert = false
        hasShownInAppAlert = true
    }

    /// Request notification permissions
    func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            notificationPermissionAsked = true

            if granted {
                await checkNotificationPermission()
            }
        } catch {
            print("NotificationService: Permission request failed: \(error)")
        }
    }

    // MARK: - Private Methods

    private func handleCreditsHitZero() {
        // Record the timestamp when credits hit 0
        if creditsHitZeroDate == nil {
            creditsHitZeroDate = Date()
        }

        // Reset in-app alert flag so it can show again
        hasShownInAppAlert = false

        // Schedule notification if not already scheduled
        if !notificationScheduled {
            Task {
                await scheduleReminderNotification()
            }
        }
    }

    private func handleCreditsRestored() {
        // Cancel any pending notification
        cancelScheduledNotification()

        // Clear the zero credits timestamp
        creditsHitZeroDate = nil
        notificationScheduled = false

        // Reset in-app alert state
        hasShownInAppAlert = false
        shouldShowInAppAlert = false
    }

    private func scheduleReminderNotification() async {
        let center = UNUserNotificationCenter.current()

        // Check permission status
        var settings = await center.notificationSettings()

        // Request permission if not authorized and not asked before
        if settings.authorizationStatus != .authorized && !notificationPermissionAsked {
            await requestNotificationPermission()
            settings = await center.notificationSettings()
        }

        guard settings.authorizationStatus == .authorized else {
            print("NotificationService: Notifications not authorized")
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Running Low on Credits?"
        content.body = "Your credits have run out. Get more credits to continue creating stunning AI flyers!"
        content.sound = .default
        content.badge = 1

        // Create trigger for 24 hours from now
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: reminderDelayHours * 60 * 60,
            repeats: false
        )

        // Create request
        let request = UNNotificationRequest(
            identifier: creditReminderIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            notificationScheduled = true
            print("NotificationService: Reminder scheduled for \(reminderDelayHours) hours")
        } catch {
            print("NotificationService: Failed to schedule notification: \(error)")
        }
    }

    private func cancelScheduledNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [creditReminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [creditReminderIdentifier])

        // Clear badge
        clearBadge()

        notificationScheduled = false
        print("NotificationService: Scheduled notification cancelled")
    }

    private func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("NotificationService: Failed to clear badge: \(error)")
            }
        }
    }

    private func checkNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        notificationPermissionStatus = settings.authorizationStatus
    }
}
