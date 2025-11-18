//
//  EntryEditView.swift
//  VoiceJournalApp (macOS)
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import VoiceJournalCore

struct EntryEditView_macOS: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: JournalEntry

    var body: some View {
        Form {
            Section("Date") {
                DatePicker("Entry Date", selection: $entry.date, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Content") {
                TextEditor(text: $entry.content)
                    .frame(minHeight: 250)
                    .font(.body)
            }

            Section("Metadata") {
                LabeledContent("Platform", value: entry.platform.rawValue)

                if let deviceName = entry.deviceName {
                    LabeledContent("Device", value: deviceName)
                }

                LabeledContent("Created") {
                    Text(entry.createdAt, style: .relative)
                        .foregroundStyle(.secondary)
                }

                if entry.modifiedAt != entry.createdAt {
                    LabeledContent("Modified") {
                        Text(entry.modifiedAt, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 500)
        .navigationTitle("Edit Entry")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    entry.modifiedAt = Date()
                    dismiss()
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    EntryEditView_macOS(entry: JournalEntry(
        content: "This is a sample journal entry for macOS preview purposes.",
        platform: .macOS,
        deviceName: "MacBook Pro"
    ))
}
