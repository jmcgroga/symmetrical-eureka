import Foundation
import AVFoundation
import Speech
import VoiceJournalCore

@MainActor
public class macOSVoiceRecordingService: NSObject, ObservableObject, VoiceInputProtocol {
    @Published public var isRecording = false
    @Published public var transcribedText = ""
    @Published public var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    public var isAvailable: Bool {
        authorizationStatus == .authorized
    }

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    public override init() {
        super.init()
        self.authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    public func requestAuthorization() async {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    continuation.resume()
                }
            }
        }
    }

    public func startRecording() throws {
        guard authorizationStatus == .authorized else {
            throw RecordingError.notAuthorized
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw RecordingError.recognitionRequestFailed
        }

        recognitionRequest.shouldReportPartialResults = true

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw RecordingError.audioEngineFailed
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                Task { @MainActor in
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self.stopRecording()
                }
            }
        }

        isRecording = true
    }

    public func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    public enum RecordingError: Error {
        case notAuthorized
        case recognitionRequestFailed
        case audioEngineFailed
    }
}
