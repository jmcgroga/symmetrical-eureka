//
//  RecordingView.swift
//  VoiceJournalApp (macOS)
//
//  Created by Claude Code
//

import SwiftUI
import AVFoundation
import Speech
import SwiftData
import VoiceJournalCore

struct RecordingView_macOS: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorder_macOS()

    var onEntryCreated: ((JournalEntry) -> Void)?

    var body: some View {
        VStack(spacing: 30) {
            // Live transcription display
            if let text = recorder.transcribedText, !text.isEmpty {
                ScrollView {
                    Text(text)
                        .font(.title3)
                        .padding()
                        .textSelection(.enabled)
                }
                .frame(maxWidth: 500, maxHeight: 200)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }

            Spacer()

            // Recording indicator
            if recorder.isRecording {
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                        .scaleEffect(recorder.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recorder.isRecording)

                    Text("Recording...")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            } else if recorder.isTranscribing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .controlSize(.large)

                    Text("Finalizing transcription...")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)

                    Text("Click to Start Recording")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Record button
            Button(action: {
                if recorder.isRecording {
                    recorder.stopRecording()
                } else {
                    recorder.startRecording()
                }
            }) {
                Circle()
                    .fill(recorder.isRecording ? Color.red : Color.blue)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    )
            }
            .buttonStyle(.plain)
            .disabled(recorder.isTranscribing)

            if let error = recorder.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }

            Spacer()
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding()
        .navigationTitle("New Entry")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onChange(of: recorder.finalTranscription) { oldValue, newValue in
            if let text = newValue, !text.isEmpty {
                // Create entry with transcribed text
                let entry = JournalEntry(
                    content: text,
                    platform: .macOS,
                    deviceName: Host.current().localizedName
                )
                modelContext.insert(entry)
                try? modelContext.save()
                onEntryCreated?(entry)
                dismiss()
            }
        }
        .onAppear {
            recorder.requestPermissions()
        }
    }
}

// MARK: - Voice Recorder for macOS
@MainActor
class VoiceRecorder_macOS: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcribedText: String?
    @Published var finalTranscription: String?
    @Published var error: String?

    nonisolated(unsafe) private var audioEngine = AVAudioEngine()
    nonisolated(unsafe) private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) private var recognitionTask: SFSpeechRecognitionTask?
    nonisolated(unsafe) private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioQueue = DispatchQueue(label: "com.voicejournal.audio", qos: .userInteractive)

    nonisolated func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor [weak self] in
                if status != .authorized {
                    self?.error = "Speech recognition not authorized. Please enable in System Settings."
                }
            }
        }

        // Request microphone permission
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                Task { @MainActor [weak self] in
                    if !granted {
                        self?.error = "Microphone access not granted"
                    }
                }
            }
        default:
            Task { @MainActor [weak self] in
                self?.error = "Microphone access denied. Please enable in System Settings > Privacy & Security > Microphone."
            }
        }
    }

    nonisolated func startRecording() {
        Task { @MainActor [weak self] in
            self?.error = nil
            self?.transcribedText = nil
            self?.finalTranscription = nil
        }

        audioQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                recognitionRequest.shouldReportPartialResults = true
                self.recognitionRequest = recognitionRequest

                let inputNode = self.audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)

                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    recognitionRequest.append(buffer)
                }

                self.audioEngine.prepare()
                try self.audioEngine.start()

                self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                    guard let self = self else { return }

                    if let result = result {
                        let transcription = result.bestTranscription.formattedString
                        let isFinal = result.isFinal
                        Task { @MainActor [weak self] in
                            self?.transcribedText = transcription
                            if isFinal {
                                self?.finalTranscription = transcription
                            }
                        }
                    }

                    if let error = error {
                        let errorMessage = error.localizedDescription
                        Task { @MainActor [weak self] in
                            self?.error = "Transcription error: \(errorMessage)"
                        }
                    }
                }

                Task { @MainActor [weak self] in
                    self?.isRecording = true
                }

            } catch {
                Task { @MainActor [weak self] in
                    self?.error = "Failed to start recording: \(error.localizedDescription)"
                }
            }
        }
    }

    nonisolated func stopRecording() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            self.audioEngine.stop()
            self.audioEngine.inputNode.removeTap(onBus: 0)
            self.recognitionRequest?.endAudio()

            Task { @MainActor [weak self] in
                self?.isRecording = false
                self?.isTranscribing = true
            }

            // Wait for final transcription
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1.5))
                guard let self = self else { return }
                self.isTranscribing = false
                if self.finalTranscription == nil {
                    self.finalTranscription = self.transcribedText
                }
            }
        }
    }
}

#Preview {
    RecordingView_macOS()
}
