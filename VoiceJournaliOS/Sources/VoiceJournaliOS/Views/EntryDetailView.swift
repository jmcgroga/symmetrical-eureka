import SwiftUI
import SwiftData
import VoiceJournalCore
import VoiceJournalStorage

public struct EntryDetailView: View {
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
                        }

                        // Generate title button
                        Button {
                            Task {
                                await generateTitle()
                            }
                        } label: {
                            if isGeneratingTitle {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                            }
                        }
                        .foregroundStyle(.blue)
                        .disabled(isGeneratingTitle || entry.content.isEmpty)
                    }
                }
                .padding()
                #if os(iOS)
                .background(Color(uiColor: .systemGray6))
                #else
                .background(Color(white: 0.95))
                #endif
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top)

                Divider()

                // Metadata section
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
                .padding(.horizontal)

                Divider()

                // Content section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    if isEditing {
                        TextEditor(text: $entry.content)
                            .frame(minHeight: 300)
                            .padding(.horizontal)
                    } else {
                        Text(entry.content)
                            .padding(.horizontal)
                    }
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
}
