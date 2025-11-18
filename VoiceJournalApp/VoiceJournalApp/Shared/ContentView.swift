//
//  ContentView.swift
//  VoiceJournalApp
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import VoiceJournalCore
import VoiceJournalStorage

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var showingRecording = false
    @State private var selectedEntry: JournalEntry?

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    #if os(iOS)
                    NavigationLink(destination: EntryEditView(entry: entry)) {
                        entryRow(entry)
                    }
                    #elseif os(macOS)
                    Button(action: {
                        selectedEntry = entry
                    }) {
                        entryRow(entry)
                    }
                    .buttonStyle(.plain)
                    #endif
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
            #if os(iOS)
            .sheet(isPresented: $showingRecording) {
                NavigationStack {
                    RecordingView()
                }
            }
            #elseif os(macOS)
            .sheet(isPresented: $showingRecording) {
                RecordingView_macOS()
            }
            .sheet(item: $selectedEntry) { entry in
                NavigationStack {
                    EntryEditView_macOS(entry: entry)
                }
            }
            #endif
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

    private func platformName() -> JournalEntry.Platform {
        #if os(iOS)
        #if targetEnvironment(macCatalyst)
        return .macOS
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPadOS : .iOS
        #endif
        #elseif os(macOS)
        return .macOS
        #else
        return .iOS
        #endif
    }

    private func deviceName() -> String {
        #if os(iOS)
        return UIDevice.current.name
        #elseif os(macOS)
        return Host.current().localizedName ?? "Mac"
        #else
        return "Unknown Device"
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(try! CloudKitSyncManager.shared.createModelContainer())
}
