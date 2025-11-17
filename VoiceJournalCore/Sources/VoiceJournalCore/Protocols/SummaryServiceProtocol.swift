import Foundation
import SwiftData

/// Protocol for AI summary generation
public protocol SummaryServiceProtocol: Sendable {
    @MainActor func generateWeeklySummary(entries: [JournalEntry]) async throws -> String
    @MainActor func getWeeklyEntries(from modelContext: ModelContext) throws -> [JournalEntry]
}
