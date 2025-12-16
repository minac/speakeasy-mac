import AVFoundation

@MainActor
class SpeechEngine: NSObject, ObservableObject {
    @Published private(set) var state: PlaybackState = .idle

    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?

    var onProgress: ((Double, NSRange) -> Void)?
    var onComplete: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks the given text with optional voice and rate
    /// - Parameters:
    ///   - text: The text to speak
    ///   - voiceIdentifier: Optional voice identifier (e.g., "com.apple.voice.compact.en-US.Samantha")
    ///   - rate: Speech rate from 0.0 (slow) to 1.0 (fast)
    func speak(text: String, voiceIdentifier: String?, rate: Float) async throws {
        guard !text.isEmpty else { return }

        // Stop any current speech
        if state != .idle {
            stop()
        }

        let utterance = AVSpeechUtterance(string: text)

        // Set voice if specified
        if let voiceIdentifier = voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        }

        // Set rate (clamp to valid range)
        utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate,
                            min(AVSpeechUtteranceMaximumSpeechRate, rate))

        currentUtterance = utterance
        state = .speaking
        synthesizer.speak(utterance)
    }

    /// Pauses the current speech
    func pause() {
        guard state == .speaking else { return }
        synthesizer.pauseSpeaking(at: .immediate)
        state = .paused
    }

    /// Resumes paused speech
    func resume() {
        guard state == .paused else { return }
        synthesizer.continueSpeaking()
        state = .speaking
    }

    /// Stops the current speech
    func stop() {
        guard state != .idle else { return }
        synthesizer.stopSpeaking(at: .immediate)
        currentUtterance = nil
        state = .idle
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechEngine: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        Task(priority: .userInitiated) { @MainActor in
            let totalCharacters = utterance.speechString.count
            let progress = totalCharacters > 0 ? Double(characterRange.location) / Double(totalCharacters) : 0.0
            onProgress?(progress, characterRange)
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task(priority: .userInitiated) { @MainActor in
            state = .idle
            currentUtterance = nil
            onComplete?()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task(priority: .userInitiated) { @MainActor in
            state = .idle
            currentUtterance = nil
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didPause utterance: AVSpeechUtterance
    ) {
        Task(priority: .userInitiated) { @MainActor in
            state = .paused
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didContinue utterance: AVSpeechUtterance
    ) {
        Task(priority: .userInitiated) { @MainActor in
            state = .speaking
        }
    }
}
