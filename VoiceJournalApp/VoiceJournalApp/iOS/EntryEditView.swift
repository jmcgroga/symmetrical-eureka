//
//  EntryEditView.swift
//  VoiceJournalApp (iOS)
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import VoiceJournalCore

struct EntryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: JournalEntry

    var body: some View {
        Form {
            Section("Date") {
                DatePicker("Entry Date", selection: $entry.date, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Content") {
                TextEditor(text: $entry.content)
                    .frame(minHeight: 200)
            }

            Section("Metadata") {
                HStack {
                    Text("Platform")
                    Spacer()
                    Text(entry.platform.rawValue)
                        .foregroundStyle(.secondary)
                }

                if let deviceName = entry.deviceName {
                    HStack {
                        Text("Device")
                        Spacer()
                        Text(deviceName)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Created")
                    Spacer()
                    Text(entry.createdAt, style: .relative)
                        .foregroundStyle(.secondary)
                }

                if entry.modifiedAt != entry.createdAt {
                    HStack {
                        Text("Modified")
                        Spacer()
                        Text(entry.modifiedAt, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Edit Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    entry.modifiedAt = Date()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EntryEditView(entry: JournalEntry(
            content: "This is a sample journal entry for preview purposes.",
            platform: .iOS,
            deviceName: "iPhone"
        ))
    }
}
