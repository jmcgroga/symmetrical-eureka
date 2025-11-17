import SwiftUI
import SwiftData
import VoiceJournalCore
import VoiceJournalStorage

public struct macOSWeeklySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var summary: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Weekly Summary")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            // Content
            ScrollView {
                if isLoading {
                    ProgressView("Generating summary...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text("Error")
                            .font(.headline)

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    Text(summary)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(width: 600, height: 500)
        .task {
            await loadSummary()
        }
    }

    private func loadSummary() async {
        isLoading = true
        errorMessage = nil

        do {
            let entries = try SummaryService.shared.getWeeklyEntries(from: modelContext)
            let generatedSummary = try await SummaryService.shared.generateWeeklySummary(entries: entries)
            summary = generatedSummary
        } catch {
            errorMessage = "Failed to generate summary: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
