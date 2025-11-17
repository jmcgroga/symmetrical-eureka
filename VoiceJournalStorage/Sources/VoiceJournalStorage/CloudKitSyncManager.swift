import Foundation
import SwiftData
import VoiceJournalCore

/// Manages iCloud synchronization for journal entries using SwiftData + CloudKit
public final class CloudKitSyncManager: Sendable {
    public static let shared = CloudKitSyncManager()

    private init() {}

    /// Creates a model container with iCloud sync enabled
    public func createModelContainer() throws -> ModelContainer {
        let schema = Schema([
            JournalEntry.self,
        ])

        // Configure for iCloud sync
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // Enable CloudKit sync
        )

        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }

    /// Creates a model container for preview/testing (no iCloud)
    public func createPreviewContainer() throws -> ModelContainer {
        let schema = Schema([
            JournalEntry.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }

    /// Check if iCloud is available
    public func isICloudAvailable() -> Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
