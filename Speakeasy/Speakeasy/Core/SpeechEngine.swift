import AVFoundation

@MainActor
class SpeechEngine: NSObject, ObservableObject {
    @Published private(set) var state: PlaybackState = .idle

    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?

    // Audio player for external audio data (Google Cloud TTS)
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?

    var onProgress: ((Double, NSRange) -> Void)?
    var onComplete: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - System TTS (AVSpeechSynthesizer)

    /// Speaks the given text with optional voice and rate
    func speak(text: String, voiceIdentifier: String?, rate: Float) async throws {
        guard !text.isEmpty else { return }

        if state != .idle {
            stop()
        }

        let utterance = AVSpeechUtterance(string: text)

        if let voiceIdentifier = voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        }

        utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate,
                            min(AVSpeechUtteranceMaximumSpeechRate, rate))

        currentUtterance = utterance
        state = .speaking
        synthesizer.speak(utterance)
    }

    // MARK: - Audio Data Playback (Google Cloud TTS)

    /// Plays pre-synthesized audio data (e.g. MP3 from Google Cloud TTS)
    func playAudio(data: Data) throws {
        if state != .idle {
            stop()
        }

        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        audioPlayer?.play()
        state = .speaking
        startProgressTimer()
    }

    // MARK: - Playback Control

    func pause() {
        guard state == .speaking else { return }
        if let player = audioPlayer {
            player.pause()
            stopProgressTimer()
        } else {
            synthesizer.pauseSpeaking(at: .immediate)
        }
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        if let player = audioPlayer {
            player.play()
            startProgressTimer()
        } else {
            synthesizer.continueSpeaking()
        }
        state = .speaking
    }

    func stop() {
        guard state != .idle else { return }
        stopProgressTimer()
        audioPlayer?.stop()
        audioPlayer = nil
        synthesizer.stopSpeaking(at: .immediate)
        currentUtterance = nil
        state = .idle
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAudioProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateAudioProgress() {
        guard let player = audioPlayer, player.duration > 0 else { return }
        let progress = player.currentTime / player.duration
        // No word-level range for audio playback — use NSRange.notFound
        onProgress?(progress, NSRange(location: NSNotFound, length: 0))
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

// MARK: - AVAudioPlayerDelegate
extension SpeechEngine: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task(priority: .userInitiated) { @MainActor in
            stopProgressTimer()
            audioPlayer = nil
            state = .idle
            onComplete?()
        }
    }
}
