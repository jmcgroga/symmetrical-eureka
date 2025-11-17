import Foundation

/// Protocol for voice input functionality (available on iOS, iPadOS, macOS)
@MainActor
public protocol VoiceInputProtocol: AnyObject {
    var isRecording: Bool { get }
    var transcribedText: String { get }
    var isAvailable: Bool { get }

    func requestAuthorization() async
    func startRecording() throws
    func stopRecording()
}
