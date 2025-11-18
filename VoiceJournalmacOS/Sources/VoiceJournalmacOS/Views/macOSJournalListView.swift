import SwiftUI
import SwiftData
import VoiceJournalCore

public struct macOSJournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var showingNewEntry = false
    @State private var showingWeeklySummary = false
    @State private var showingSettings = false
    @State private var selectedEntry: JournalEntry?
    @State private var searchText = ""

    public init() {}

    public var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack {
                List(selection: $selectedEntry) {
                    ForEach(filteredEntries) { entry in
                        NavigationLink(value: entry) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(entry.date))
                                    .font(.headline)

                                if let title = entry.title, !title.isEmpty {
                                    Text(title)
                                        .lineLimit(1)
                                        .font(.subheadline)

                                    Text(entry.content)
                                        .lineLimit(1)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(entry.content)
                                        .lineLimit(2)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if let device = entry.deviceName {
                                    Text(device)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
                .searchable(text: $searchText, prompt: "Search entries")
                .navigationTitle("Journal")
                .toolbar {
                    ToolbarItem {
                        Button {
                            showingNewEntry = true
                        } label: {
                            Label("New Entry", systemImage: "plus")
                        }
                    }

                    ToolbarItem {
                        Button {
                            showingWeeklySummary = true
                        } label: {
                            Label("Weekly Summary", systemImage: "chart.bar.doc.horizontal")
                        }
                    }

                    ToolbarItem {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                }
            }
        } detail: {
            if let entry = selectedEntry {
                macOSEntryDetailView(entry: entry)
            } else {
                ContentUnavailableView(
                    "Select an Entry",
                    systemImage: "book.closed",
                    description: Text("Choose an entry from the sidebar to view its details")
                )
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            macOSJournalEntryView()
        }
        .sheet(isPresented: $showingWeeklySummary) {
            macOSWeeklySummaryView()
        }
        .sheet(isPresented: $showingSettings) {
            macOSSettingsView()
        }
    }

    private var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return entries
        }
        return entries.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}
