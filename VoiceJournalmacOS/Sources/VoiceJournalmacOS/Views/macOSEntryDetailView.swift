import SwiftUI
import SwiftData
import VoiceJournalCore
import VoiceJournalStorage

public struct macOSEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var entry: JournalEntry
    @State private var isEditing = false
    @State private var isGeneratingTitle = false
    @State private var showingTitleError = false
    @State private var titleErrorMessage = ""

    public init(entry: JournalEntry) {
        self.entry = entry
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Title")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        if isEditing {
                            TextField("Enter title", text: Binding(
                                get: { entry.title ?? "" },
                                set: { entry.title = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                        } else {
                            Text(entry.title ?? "No title")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(entry.title == nil ? .secondary : .primary)
                                .textSelection(.enabled)
                        }

                        // Generate title button
                        Button {
                            Task {
                                await generateTitle()
                            }
                        } label: {
                            if isGeneratingTitle {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                            }
                        }
                        .buttonStyle(.borderless)
                        .disabled(isGeneratingTitle || entry.content.isEmpty)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                Divider()

                // Header/Metadata
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
                .padding(.horizontal)

                Divider()

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    if isEditing {
                        TextEditor(text: $entry.content)
                            .font(.body)
                            .frame(minHeight: 400)
                            .border(Color.gray.opacity(0.2), width: 1)
                            .padding(.horizontal)
                    } else {
                        Text(entry.content)
                            .font(.body)
                            .textSelection(.enabled)
                            .padding(.horizontal)
                    }
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
        .alert("Title Generation Error", isPresented: $showingTitleError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(titleErrorMessage)
        }
    }

    @MainActor
    private func generateTitle() async {
        isGeneratingTitle = true
        defer { isGeneratingTitle = false }

        do {
            let newTitle = try await SummaryService.shared.generateTitle(for: entry.content)
            entry.title = newTitle
            entry.modifiedAt = Date()
            try? modelContext.save()
        } catch {
            titleErrorMessage = error.localizedDescription
            showingTitleError = true
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
