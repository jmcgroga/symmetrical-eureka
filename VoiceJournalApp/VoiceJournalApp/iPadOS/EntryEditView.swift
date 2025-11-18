//
//  EntryEditView.swift
//  VoiceJournalApp (iPadOS)
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import VoiceJournalCore

struct EntryEditView_iPadOS: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: JournalEntry

    var body: some View {
        Form {
            Section("Date") {
                DatePicker("Entry Date", selection: $entry.date, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Content") {
                TextEditor(text: $entry.content)
                    .frame(minHeight: 300)
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
        EntryEditView_iPadOS(entry: JournalEntry(
            content: "This is a sample journal entry for iPad preview purposes. The larger screen allows for more comfortable editing.",
            platform: .iPadOS,
            deviceName: "iPad Pro"
        ))
    }
}
