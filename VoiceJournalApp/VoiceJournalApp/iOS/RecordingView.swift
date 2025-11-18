//
//  RecordingView.swift
//  VoiceJournalApp (iOS)
//
//  Created by Claude Code
//

import SwiftUI
import AVFoundation
import Speech
import SwiftData
import VoiceJournalCore

struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorder()

    var onEntryCreated: ((JournalEntry) -> Void)?

    var body: some View {
        VStack(spacing: 30) {
            // Live transcription display
            if let text = recorder.transcribedText, !text.isEmpty {
                ScrollView {
                    Text(text)
                        .font(.body)
                        .padding()
                }
                .frame(maxHeight: 150)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            Spacer()

            // Recording indicator
            if recorder.isRecording {
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .scaleEffect(recorder.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recorder.isRecording)

                    Text("Recording...")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            } else if recorder.isTranscribing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Transcribing...")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Tap to Record")
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
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    )
            }
            .disabled(recorder.isTranscribing)

            if let error = recorder.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("New Entry")
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
                    platform: .iOS,
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

// MARK: - Voice Recorder
@MainActor
class VoiceRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcribedText: String?
    @Published var finalTranscription: String?
    @Published var error: String?

    nonisolated(unsafe) private var audioRecorder: AVAudioRecorder?
    nonisolated(unsafe) private var audioEngine = AVAudioEngine()
    nonisolated(unsafe) private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) private var recognitionTask: SFSpeechRecognitionTask?
    nonisolated(unsafe) private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioQueue = DispatchQueue(label: "com.voicejournal.audio.ios", qos: .userInteractive)

    private var recordingURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("recording.m4a")
    }

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

                // Setup recognition
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

                    if error != nil || result?.isFinal == true {
                        self.audioEngine.stop()
                        inputNode.removeTap(onBus: 0)
                        Task { @MainActor [weak self] in
                            self?.recognitionRequest = nil
                            self?.recognitionTask = nil
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
            self.recognitionRequest?.endAudio()

            Task { @MainActor [weak self] in
                self?.isRecording = false
                self?.isTranscribing = true
            }

            // Wait a moment for final transcription
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1.0))
                guard let self = self else { return }
                self.isTranscribing = false
                // If we didn't get a final transcription, use the partial one
                if self.finalTranscription == nil {
                    self.finalTranscription = self.transcribedText
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecordingView()
    }
}
