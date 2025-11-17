import Foundation
@preconcurrency import UserNotifications
import VoiceJournalCore

public final class NotificationService: NotificationServiceProtocol, Sendable {
    public static let shared = NotificationService()

    private nonisolated(unsafe) let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    public func requestAuthorization() async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }

    public func scheduleDailyNotification(at time: DateComponents) async throws {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily-journal"])

        let content = UNMutableNotificationContent()
        content.title = "Daily Journal"
        content.body = "Take a moment to reflect on your day"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-journal",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    public func scheduleWeeklyNotification(day: Int, at time: DateComponents) async throws {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["weekly-summary"])

        let content = UNMutableNotificationContent()
        content.title = "Weekly Journal Summary"
        content.body = "Your weekly reflection is ready to review"
        content.sound = .default

        var dateComponents = time
        dateComponents.weekday = day

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly-summary",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    public func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    public func updateNotifications(settings: AppSettings) async throws {
        guard settings.notificationsEnabled else {
            cancelAllNotifications()
            return
        }

        try await scheduleDailyNotification(at: settings.dailyNotificationTime)
        try await scheduleWeeklyNotification(
            day: settings.weeklyNotificationDay,
            at: settings.weeklyNotificationTime
        )
    }
}
