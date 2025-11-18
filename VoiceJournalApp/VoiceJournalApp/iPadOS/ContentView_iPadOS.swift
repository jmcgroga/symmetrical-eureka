//
//  ContentView_iPadOS.swift
//  VoiceJournalApp (iPadOS)
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import VoiceJournalCore
import VoiceJournalStorage

struct ContentView_iPadOS: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var showingRecording = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    NavigationLink(destination: EntryEditView_iPadOS(entry: entry)) {
                        entryRow(entry)
                    }
                }
            }
            .navigationTitle("Voice Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingRecording = true }) {
                        Label("New Entry", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingRecording) {
                NavigationStack {
                    RecordingView_iPadOS()
                }
            }
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.date, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !entry.content.isEmpty {
                Text(entry.content)
                    .lineLimit(3)
            }

            HStack {
                Label(entry.platform.rawValue, systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if let deviceName = entry.deviceName {
                    Text(deviceName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView_iPadOS()
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
}
