import Foundation
import SwiftData

/// Core journal entry model with iCloud sync support
@Model
public final class JournalEntry {
    public var id: UUID
    public var date: Date
    public var content: String
    public var createdAt: Date
    public var modifiedAt: Date

    // Platform-specific metadata
    public var platform: Platform
    public var deviceName: String?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        content: String = "",
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        platform: Platform = .iOS,
        deviceName: String? = nil
    ) {
        self.id = id
        self.date = date
        self.content = content
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.platform = platform
        self.deviceName = deviceName
    }
}

// MARK: - Platform Enum
extension JournalEntry {
    public enum Platform: String, Codable {
        case iOS
        case iPadOS
        case macOS
    }
}
