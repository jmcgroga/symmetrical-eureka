import SwiftUI
import SwiftData
import VoiceJournalCore
import VoiceJournalStorage

public struct WeeklySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var summary: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        ProgressView("Generating summary...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let error = errorMessage {
                        ContentUnavailableView(
                            "Error",
                            systemImage: "exclamationmark.triangle",
                            description: Text(error)
                        )
                    } else {
                        Text(summary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("Weekly Summary")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadSummary()
            }
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
