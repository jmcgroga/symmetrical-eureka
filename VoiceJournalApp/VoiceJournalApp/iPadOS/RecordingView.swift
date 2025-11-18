//
//  RecordingView.swift
//  VoiceJournalApp (iPadOS)
//
//  Created by Claude Code
//

import SwiftUI
import AVFoundation
import Speech
import SwiftData
import VoiceJournalCore

struct RecordingView_iPadOS: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorder_iPadOS()

    var onEntryCreated: ((JournalEntry) -> Void)?

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Live transcription display
            if let text = recorder.transcribedText, !text.isEmpty {
                ScrollView {
                    Text(text)
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: 600)
                }
                .frame(maxHeight: 300)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            // Recording indicator
            if recorder.isRecording {
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 24, height: 24)
                        .scaleEffect(recorder.isRecording ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recorder.isRecording)

                    Text("Recording...")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            } else if recorder.isTranscribing {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.8)

                    Text("Finalizing transcription...")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)

                    Text("Tap to Start Recording")
                        .font(.title)
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
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    )
                    .shadow(radius: 8)
            }
            .disabled(recorder.isTranscribing)

            if let error = recorder.error {
                Text(error)
                    .font(.body)
                    .foregroundStyle(.red)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("New Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
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
                    platform: .iPadOS,
                    deviceName: UIDevice.current.name
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

// MARK: - Voice Recorder for iPadOS
@MainActor
class VoiceRecorder_iPadOS: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcribedText: String?
    @Published var finalTranscription: String?
    @Published var error: String?

    nonisolated(unsafe) private var audioEngine = AVAudioEngine()
    nonisolated(unsafe) private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) private var recognitionTask: SFSpeechRecognitionTask?
    nonisolated(unsafe) private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioQueue = DispatchQueue(label: "com.voicejournal.audio.ipados", qos: .userInteractive)

    nonisolated func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor [weak self] in
                if status != .authorized {
                    self?.error = "Speech recognition not authorized"
                }
            }
        }

        AVAudioApplication.requestRecordPermission { granted in
            Task { @MainActor [weak self] in
                if !granted {
                    self?.error = "Microphone access not granted"
                }
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

            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .default)
                try audioSession.setActive(true)

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
                let errorMessage = error.localizedDescription
                Task { @MainActor [weak self] in
                    self?.error = "Failed to start recording: \(errorMessage)"
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
    NavigationStack {
        RecordingView_iPadOS()
    }
}
