import Foundation
import SwiftData
import VoiceJournalCore
import NaturalLanguage

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

    @MainActor
    public func generateTitle(for content: String, mode: AppSettings.AISummarizationMode) async throws -> String {
        guard !content.isEmpty else {
            return "Untitled Entry"
        }

        switch mode {
        case .onDevice:
            return try await generateTitleOnDevice(for: content)
        case .cloud:
            return try await generateTitleInCloud(for: content)
        }
    }

    // MARK: - On-Device Title Generation
    @MainActor
    private func generateTitleOnDevice(for content: String) async throws -> String {
        // Use NaturalLanguage framework for on-device processing
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = content

        // Extract key phrases and entities
        var keywords: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(in: content.startIndex..<content.endIndex,
                            unit: .word,
                            scheme: .lexicalClass,
                            options: options) { tag, tokenRange in
            if let tag = tag, tag == .noun || tag == .verb {
                let word = String(content[tokenRange])
                if word.count > 3 {  // Filter short words
                    keywords.append(word)
                }
            }
            return true
        }

        // Generate title from first sentence or key phrases
        if let firstSentence = extractFirstSentence(from: content) {
            return truncateTitle(firstSentence)
        }

        // Fallback: use first few words
        let words = content.split(separator: " ").prefix(5)
        if !words.isEmpty {
            return truncateTitle(words.joined(separator: " "))
        }

        return "Untitled Entry"
    }

    // MARK: - Cloud-Based Title Generation
    @MainActor
    private func generateTitleInCloud(for content: String) async throws -> String {
        // For cloud-based processing, we'll use a more sophisticated approach
        // In a real implementation, this would call Apple Intelligence cloud APIs
        // For now, we'll use enhanced on-device processing with better algorithms

        let cleaned = cleanText(content)

        // Try to extract the main theme or topic
        let tagger = NLTagger(tagSchemes: [.nameType, .lemma])
        tagger.string = cleaned

        var entities: [String] = []
        tagger.enumerateTags(in: cleaned.startIndex..<cleaned.endIndex,
                           unit: .word,
                           scheme: .nameType,
                           options: [.omitPunctuation, .omitWhitespace]) { tag, tokenRange in
            if let tag = tag {
                let entity = String(cleaned[tokenRange])
                entities.append(entity)
            }
            return true
        }

        // If we found named entities, use them in the title
        if !entities.isEmpty {
            let title = entities.prefix(3).joined(separator: ", ")
            return truncateTitle(title)
        }

        // Extract first meaningful sentence
        if let firstSentence = extractFirstSentence(from: cleaned) {
            return truncateTitle(firstSentence)
        }

        // Fallback to first few words
        let words = cleaned.split(separator: " ").prefix(6)
        if !words.isEmpty {
            return truncateTitle(words.joined(separator: " "))
        }

        return "Untitled Entry"
    }

    // MARK: - Helper Methods
    private func extractFirstSentence(from text: String) -> String? {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        if let range = tokenizer.tokenRange(at: text.startIndex) {
            return String(text[range])
        }

        return nil
    }

    private func cleanText(_ text: String) -> String {
        // Remove extra whitespace and newlines
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let singleSpaced = cleaned.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return singleSpaced
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
