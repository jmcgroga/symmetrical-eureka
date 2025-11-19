import Foundation
import SwiftData

/// Protocol for AI summary generation using Apple's Foundation Models framework
public protocol SummaryServiceProtocol: Sendable {
    @MainActor func generateWeeklySummary(entries: [JournalEntry]) async throws -> String
    @MainActor func getWeeklyEntries(from modelContext: ModelContext) throws -> [JournalEntry]
    @MainActor func generateTitle(for content: String) async throws -> String
}
