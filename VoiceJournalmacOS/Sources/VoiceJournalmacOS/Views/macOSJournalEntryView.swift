import SwiftUI
import SwiftData
import VoiceJournalCore

public struct macOSJournalEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var voiceService = macOSVoiceRecordingService()
    @State private var entryText = ""
    @State private var selectedDate = Date()
    @State private var showingError = false
    @State private var errorMessage = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("New Journal Entry")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    saveEntry()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Content
            VStack(spacing: 16) {
                DatePicker("Entry Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.field)
                    .frame(maxWidth: 300, alignment: .leading)

                ZStack(alignment: .topLeading) {
                    if entryText.isEmpty {
                        Text("Write your thoughts here...")
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }

                    TextEditor(text: $entryText)
                        .font(.body)
                        .frame(minHeight: 300)
                        .border(Color.gray.opacity(0.2), width: 1)
                        .onChange(of: voiceService.transcribedText) { oldValue, newValue in
                            if !newValue.isEmpty && newValue != oldValue {
                                if !entryText.isEmpty {
                                    entryText += " "
                                }
                                entryText += newValue
                            }
                        }
                }

                // Voice controls
                HStack {
                    Button {
                        if voiceService.isRecording {
                            voiceService.stopRecording()
                        } else {
                            startRecording()
                        }
                    } label: {
                        HStack {
                            Image(systemName: voiceService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                                .foregroundStyle(voiceService.isRecording ? .red : .blue)

                            Text(voiceService.isRecording ? "Stop Recording" : "Start Recording")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!voiceService.isAvailable)

                    if voiceService.authorizationStatus != .authorized {
                        Button("Request Microphone Permission") {
                            Task {
                                await voiceService.requestAuthorization()
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
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
        let entry = JournalEntry(
            date: selectedDate,
            content: entryText.trimmingCharacters(in: .whitespacesAndNewlines),
            platform: .macOS,
            deviceName: Host.current().localizedName
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
