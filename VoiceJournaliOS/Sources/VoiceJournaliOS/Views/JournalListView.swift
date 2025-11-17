import SwiftUI
import SwiftData
import VoiceJournalCore

public struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var showingNewEntry = false
    @State private var showingWeeklySummary = false
    @State private var showingSettings = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                ForEach(groupedEntries.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(formatSectionHeader(date))) {
                        ForEach(groupedEntries[date] ?? []) { entry in
                            NavigationLink {
                                EntryDetailView(entry: entry)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.content)
                                        .lineLimit(2)
                                        .font(.body)

                                    HStack {
                                        Text(formatTime(entry.createdAt))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        if let device = entry.deviceName {
                                            Text("• \(device)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            deleteEntries(at: indexSet, in: groupedEntries[date] ?? [])
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingWeeklySummary = true
                    } label: {
                        Label("Weekly Summary", systemImage: "chart.bar.doc.horizontal")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    HStack {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }

                        Button {
                            showingNewEntry = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryView()
            }
            .sheet(isPresented: $showingWeeklySummary) {
                WeeklySummaryView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Entries Yet",
                        systemImage: "book.closed",
                        description: Text("Tap + to create your first journal entry")
                    )
                }
            }
        }
    }

    private var groupedEntries: [Date: [JournalEntry]] {
        Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
    }

    private func formatSectionHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func deleteEntries(at offsets: IndexSet, in entries: [JournalEntry]) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}
