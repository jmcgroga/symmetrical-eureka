import Foundation
import SwiftData
import VoiceJournalCore
import FoundationModels

/// Generated title structure for guided generation
@Generable
struct GeneratedTitle {
    @Guide(description: "A concise, descriptive title for the journal entry (3-8 words)")
    let title: String
}

/// Generated summary structure for guided generation
@Generable
struct GeneratedSummary {
    @Guide(description: "Key themes identified in the journal entries")
    let themes: [String]

    @Guide(description: "A brief overall summary of the week's entries (2-3 sentences)")
    let summary: String
}

/// Shared summary service implementation using Apple's Foundation Models framework
public final class SummaryService: SummaryServiceProtocol, Sendable {
    public static let shared = SummaryService()

    private init() {}

    @MainActor
    public func generateWeeklySummary(entries: [JournalEntry]) async throws -> String {
        guard !entries.isEmpty else {
            return "No journal entries found for this week."
        }

        // Check model availability safely
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return generateFallbackSummary(entries: entries)
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

        let session = LanguageModelSession(instructions: """
            You are a helpful assistant that summarizes journal entries.
            Identify key themes, emotions, and notable events from the entries.
            Be concise and insightful.
            """)

        do {
            let response = try await session.respond(
                to: "Summarize these journal entries from the past week:\n\n\(combinedText)",
                generating: GeneratedSummary.self
            )

            let themes = response.content.themes.prefix(5).map { "• \($0)" }.joined(separator: "\n")

            return """
            📊 Weekly Journal Summary

            This week you created \(entries.count) journal \(entries.count == 1 ? "entry" : "entries") across your devices.

            ✨ Key Themes:
            \(themes)

            📝 Summary:
            \(response.content.summary)

            📱 Cross-Device Journaling:
            Your entries are synchronized via iCloud and available on all your devices.
            """
        } catch {
            // Fall back to basic summary if AI generation fails
            return generateFallbackSummary(entries: entries)
        }
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

    /// Errors that can occur during title generation
    public enum TitleGenerationError: LocalizedError {
        case emptyContent
        case modelUnavailable(String)
        case generationFailed(Error)

        public var errorDescription: String? {
            switch self {
            case .emptyContent:
                return "Cannot generate title for empty content."
            case .modelUnavailable(let reason):
                return "Apple Intelligence is not available: \(reason)"
            case .generationFailed(let error):
                return "Failed to generate title: \(error.localizedDescription)"
            }
        }
    }

    @MainActor
    public func generateTitle(for content: String) async throws -> String {
        guard !content.isEmpty else {
            throw TitleGenerationError.emptyContent
        }

        // Check model availability safely
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw TitleGenerationError.modelUnavailable(String(describing: reason))
        }

        do {
            let session = LanguageModelSession(instructions: """
                Generate a concise, descriptive title for a journal entry.
                The title should capture the main theme or topic in 3-8 words.
                Do not use quotes or punctuation at the end.
                """)

            let response = try await session.respond(
                to: "Generate a title for this journal entry:\n\n\(content.prefix(1000))",
                generating: GeneratedTitle.self
            )

            let generatedTitle = response.content.title
            if generatedTitle.isEmpty {
                throw TitleGenerationError.generationFailed(NSError(domain: "SummaryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "AI returned empty title"]))
            }
            return truncateTitle(generatedTitle)
        } catch let error as TitleGenerationError {
            throw error
        } catch {
            throw TitleGenerationError.generationFailed(error)
        }
    }

    /// Generate a default title using the entry's creation date
    public func defaultTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Journal Entry: \(formatter.string(from: date))"
    }

    // MARK: - Fallback Methods

    private func generateFallbackSummary(entries: [JournalEntry]) -> String {
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

        return """
        📊 Weekly Journal Summary

        This week you created \(entries.count) journal \(entries.count == 1 ? "entry" : "entries") across your devices.

        ✨ Key Themes:
        • Reflection and personal growth
        • Daily experiences and observations
        • Thoughts and feelings captured throughout the week

        📱 Cross-Device Journaling:
        Your entries are synchronized via iCloud and available on all your devices.

        ───────────────────

        \(combinedText)
        """
    }

    private func truncateTitle(_ title: String, maxLength: Int = 60) -> String {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.count <= maxLength {
            return cleaned
        }

        // Truncate at word boundary
        let truncated = String(cleaned.prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }

        return truncated + "..."
    }
}
