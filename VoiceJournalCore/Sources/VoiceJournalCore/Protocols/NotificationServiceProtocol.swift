import Foundation

/// Protocol for platform-specific notification implementations
public protocol NotificationServiceProtocol {
    func requestAuthorization() async throws -> Bool
    func scheduleDailyNotification(at time: DateComponents) async throws
    func scheduleWeeklyNotification(day: Int, at time: DateComponents) async throws
    func cancelAllNotifications()
    func updateNotifications(settings: AppSettings) async throws
}
