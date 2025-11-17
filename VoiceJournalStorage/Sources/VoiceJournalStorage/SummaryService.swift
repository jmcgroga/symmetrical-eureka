import Foundation
import SwiftData
import VoiceJournalCore

/// Shared summary service implementation
public final class SummaryService: SummaryServiceProtocol, Sendable {
    public static let shared = SummaryService()

    private init() {}

    @MainActor
    public func generateWeeklySummary(entries: [JournalEntry]) async throws -> String {
        guard !entries.isEmpty else {
            return "No journal entries found for this week."
        }

        let combinedText = entries
            .sorted { $0.date < $1.date }
            .map { entry in
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let platform = entry.platform.rawValue
                let device = entry.deviceName ?? "Unknown Device"
                return "\(dateFormatter.string(from: entry.date)) (\(platform) - \(device)):\n\(entry.content)"
            }
            .joined(separator: "\n\n")

        return try await generateSummaryText(from: combinedText, entryCount: entries.count)
    }

    @MainActor
    public func getWeeklyEntries(from modelContext: ModelContext) throws -> [JournalEntry] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            return []
        }

        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= weekAgo && entry.date <= now
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        return try modelContext.fetch(descriptor)
    }

    private func generateSummaryText(from text: String, entryCount: Int) async throws -> String {
        // Platform-specific Apple Intelligence integration would go here
        // For now, provide a structured summary

        return """
        📊 Weekly Journal Summary

        This week you created \(entryCount) journal \(entryCount == 1 ? "entry" : "entries") across your devices.

        ✨ Key Themes:
        • Reflection and personal growth
        • Daily experiences and observations
        • Thoughts and feelings captured throughout the week

        📱 Cross-Device Journaling:
        Your entries are synchronized via iCloud and available on all your devices.

        ───────────────────

        \(text)
        """
    }
}
