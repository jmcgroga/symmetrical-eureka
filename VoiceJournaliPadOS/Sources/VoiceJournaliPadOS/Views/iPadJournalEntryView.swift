import SwiftUI
import SwiftData
import VoiceJournalCore
import VoiceJournaliOS
import VoiceJournalStorage
#if os(iOS)
import PencilKit
#endif

/// Enhanced journal entry view for iPadOS with Apple Pencil and Scribble support
public struct iPadJournalEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var voiceService = VoiceRecordingService()
    @State private var entryText = ""
    @State private var selectedDate = Date()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDrawingCanvas = false
    @State private var isSaving = false
    #if os(iOS)
    @State private var canvasView = PKCanvasView()
    #endif

    public init() {}

    public var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Main entry area
                VStack(spacing: 20) {
                    DatePicker("Entry Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal)

                    ZStack(alignment: .topLeading) {
                        if entryText.isEmpty {
                            Text("Write your thoughts here...\n\nTip: Use Apple Pencil with Scribble to convert handwriting to text")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                        }

                        TextEditor(text: $entryText)
                            .frame(minHeight: 300)
                            .scrollContentBackground(.hidden)
                            #if os(iOS)
                            .background(Color(.systemGray6))
                            #else
                            .background(Color(white: 0.95))
                            #endif
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            // Scribble is automatically enabled on iPadOS
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

                    // Voice recording button
                    HStack(spacing: 20) {
                        #if os(iOS)
                        Button {
                            showingDrawingCanvas.toggle()
                        } label: {
                            Label("Drawing", systemImage: showingDrawingCanvas ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
                                .font(.headline)
                        }
                        .buttonStyle(.bordered)
                        #endif

                        Spacer()

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

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }

                // Drawing canvas (when enabled)
                #if os(iOS)
                if showingDrawingCanvas {
                    Divider()

                    VStack {
                        HStack {
                            Text("Sketch")
                                .font(.headline)

                            Spacer()

                            Button("Clear") {
                                canvasView.drawing = PKDrawing()
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                        }
                        .padding()

                        DrawingCanvasView(canvasView: $canvasView)
                            .frame(width: 300)
                            .background(Color(.systemBackground))
                    }
                }
                #endif
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
                        Task {
                            await saveEntry()
                        }
                    }
                    .disabled(entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
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

    @MainActor
    private func saveEntry() async {
        isSaving = true
        defer { isSaving = false }

        #if os(iOS)
        let deviceName = UIDevice.current.name
        #else
        let deviceName: String? = nil
        #endif

        let content = entryText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Generate title using AI
        let settings = AppSettings.load()
        let title: String?
        do {
            title = try await SummaryService.shared.generateTitle(for: content, mode: settings.aiSummarizationMode)
        } catch {
            // If title generation fails, continue without a title
            title = nil
        }

        let entry = JournalEntry(
            date: selectedDate,
            content: content,
            title: title,
            platform: .iPadOS,
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

// MARK: - Drawing Canvas View
#if os(iOS)
struct DrawingCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
#endif
