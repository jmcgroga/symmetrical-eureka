import SwiftUI
import SwiftData
import VoiceJournalCore

public struct macOSEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var entry: JournalEntry
    @State private var isEditing = false

    public init(entry: JournalEntry) {
        self.entry = entry
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(formatDate(entry.date))
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack {
                        Label(formatDateTime(entry.createdAt), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if entry.modifiedAt != entry.createdAt {
                            Label("Modified: \(formatDateTime(entry.modifiedAt))", systemImage: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        if let device = entry.deviceName {
                            Label(device, systemImage: "desktopcomputer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Label(entry.platform.rawValue, systemImage: platformIcon(entry.platform))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                Divider()

                // Content
                if isEditing {
                    TextEditor(text: $entry.content)
                        .font(.body)
                        .frame(minHeight: 400)
                        .border(Color.gray.opacity(0.2), width: 1)
                        .padding()
                } else {
                    Text(entry.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                }
            }
        }
        .toolbar {
            Button(isEditing ? "Done" : "Edit") {
                if isEditing {
                    entry.modifiedAt = Date()
                    try? modelContext.save()
                }
                isEditing.toggle()
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

    private func platformIcon(_ platform: JournalEntry.Platform) -> String {
        switch platform {
        case .iOS: return "iphone"
        case .iPadOS: return "ipad"
        case .macOS: return "macbook"
        }
    }
}
