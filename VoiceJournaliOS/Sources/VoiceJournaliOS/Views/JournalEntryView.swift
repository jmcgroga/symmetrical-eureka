import SwiftUI
import SwiftData
import VoiceJournalCore

public struct JournalEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var voiceService = VoiceRecordingService()
    @State private var entryText = ""
    @State private var selectedDate = Date()
    @State private var showingError = false
    @State private var errorMessage = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker("Entry Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)

                ZStack(alignment: .topLeading) {
                    if entryText.isEmpty {
                        Text("Write your thoughts here...")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                    }

                    TextEditor(text: $entryText)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                        #if os(iOS)
                        .background(Color(.systemGray6))
                        #else
                        .background(Color(white: 0.95))
                        #endif
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: voiceService.transcribedText) { oldValue, newValue in
                            if !newValue.isEmpty && newValue != oldValue {
                                if !entryText.isEmpty {
                                    entryText += " "
                                }
                                entryText += newValue
                            }
                        }
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Button(action: {}) {
                        Circle()
                            .fill(voiceService.isRecording ? Color.red : Color.blue)
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white)
                            }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !voiceService.isRecording {
                                    startRecording()
                                }
                            }
                            .onEnded { _ in
                                if voiceService.isRecording {
                                    voiceService.stopRecording()
                                }
                            }
                    )

                    Text(voiceService.isRecording ? "Recording..." : "Hold to record")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom)

                Spacer()
            }
            .navigationTitle("New Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                if voiceService.authorizationStatus == .notDetermined {
                    await voiceService.requestAuthorization()
                }
            }
        }
    }

    private func startRecording() {
        voiceService.transcribedText = ""

        do {
            try voiceService.startRecording()
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func saveEntry() {
        #if os(iOS)
        let platform: JournalEntry.Platform = UIDevice.current.userInterfaceIdiom == .pad ? .iPadOS : .iOS
        let deviceName = UIDevice.current.name
        #else
        let platform: JournalEntry.Platform = .iOS
        let deviceName: String? = nil
        #endif

        let entry = JournalEntry(
            date: selectedDate,
            content: entryText.trimmingCharacters(in: .whitespacesAndNewlines),
            platform: platform,
            deviceName: deviceName
        )

        modelContext.insert(entry)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save entry: \(error.localizedDescription)"
            showingError = true
        }
    }
}
