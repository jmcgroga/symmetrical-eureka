import SwiftUI
import SwiftData
import VoiceJournalCore

public struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var entry: JournalEntry
    @State private var isEditing = false

    public init(entry: JournalEntry) {
        self.entry = entry
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(entry.date))
                        .font(.headline)

                    Text("Created: \(formatDateTime(entry.createdAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if entry.modifiedAt != entry.createdAt {
                        Text("Modified: \(formatDateTime(entry.modifiedAt))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let device = entry.deviceName {
                        Text("Device: \(device)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Platform: \(entry.platform.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()

                Divider()

                if isEditing {
                    TextEditor(text: $entry.content)
                        .frame(minHeight: 300)
                        .padding()
                } else {
                    Text(entry.content)
                        .padding()
                }
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        entry.modifiedAt = Date()
                        try? modelContext.save()
                    }
                    isEditing.toggle()
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
