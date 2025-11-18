import Foundation

/// Shared application settings synchronized via iCloud
public struct AppSettings: Codable, Sendable {
    public var dailyNotificationTime: DateComponents
    public var weeklyNotificationDay: Int // 1 = Sunday, 7 = Saturday
    public var weeklyNotificationTime: DateComponents
    public var notificationsEnabled: Bool
    public var iCloudSyncEnabled: Bool
    public var aiSummarizationMode: AISummarizationMode

    public init(
        dailyNotificationTime: DateComponents = DateComponents(hour: 20, minute: 0),
        weeklyNotificationDay: Int = 1,
        weeklyNotificationTime: DateComponents = DateComponents(hour: 10, minute: 0),
        notificationsEnabled: Bool = true,
        iCloudSyncEnabled: Bool = true,
        aiSummarizationMode: AISummarizationMode = .onDevice
    ) {
        self.dailyNotificationTime = dailyNotificationTime
        self.weeklyNotificationDay = weeklyNotificationDay
        self.weeklyNotificationTime = weeklyNotificationTime
        self.notificationsEnabled = notificationsEnabled
        self.iCloudSyncEnabled = iCloudSyncEnabled
        self.aiSummarizationMode = aiSummarizationMode
    }

    // iCloud key-value store sync
    public static func load() -> AppSettings {
        let ubiquitousStore = NSUbiquitousKeyValueStore.default
        ubiquitousStore.synchronize()

        // Try to load from iCloud first
        if let data = ubiquitousStore.data(forKey: "AppSettings"),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return settings
        }

        // Fallback to UserDefaults
        if let data = UserDefaults.standard.data(forKey: "AppSettings"),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return settings
        }

        return AppSettings()
    }

    public func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }

        // Save to UserDefaults (local backup)
        UserDefaults.standard.set(data, forKey: "AppSettings")

        // Save to iCloud if enabled
        if iCloudSyncEnabled {
            let ubiquitousStore = NSUbiquitousKeyValueStore.default
            ubiquitousStore.set(data, forKey: "AppSettings")
            ubiquitousStore.synchronize()
        }
    }
}

// MARK: - AI Summarization Mode
extension AppSettings {
    /// Determines whether Apple Intelligence runs on-device or in the cloud
    public enum AISummarizationMode: String, Codable, CaseIterable, Sendable {
        case onDevice = "On-Device"
        case cloud = "Cloud"

        public var description: String {
            switch self {
            case .onDevice:
                return "Process locally for privacy"
            case .cloud:
                return "Use cloud for enhanced capabilities"
            }
        }
    }
}
