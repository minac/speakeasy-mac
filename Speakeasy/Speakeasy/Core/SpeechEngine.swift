import AVFoundation

@MainActor
class SpeechEngine: NSObject, ObservableObject {
    @Published private(set) var state: PlaybackState = .idle

    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?

    // Audio player for external audio data (Google Cloud TTS)
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?

    // Sentence ranges for line-level highlighting during audio playback
    private var sentenceRanges: [NSRange] = []
    private var totalTextLength: Int = 0

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

        sentenceRanges = []
        totalTextLength = 0

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

    /// Plays pre-synthesized audio data with sentence-level highlighting
    func playAudio(data: Data, text: String) throws {
        if state != .idle {
            stop()
        }

        // Pre-compute sentence ranges for line-level highlighting
        sentenceRanges = Self.computeSentenceRanges(from: text)
        totalTextLength = text.utf16.count

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
        sentenceRanges = []
        totalTextLength = 0
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

        // Estimate which sentence is being spoken based on progress
        let highlightRange = estimateSentenceRange(at: progress)
        onProgress?(progress, highlightRange)
    }

    /// Maps playback progress to the sentence range currently being spoken.
    /// Assumes speaking rate is roughly proportional to character count.
    private func estimateSentenceRange(at progress: Double) -> NSRange {
        guard !sentenceRanges.isEmpty, totalTextLength > 0 else {
            return NSRange(location: NSNotFound, length: 0)
        }

        let charPosition = Int(progress * Double(totalTextLength))

        for range in sentenceRanges {
            if charPosition >= range.location && charPosition < range.location + range.length {
                return range
            }
        }

        // Past end — highlight last sentence
        return sentenceRanges.last ?? NSRange(location: NSNotFound, length: 0)
    }

    // MARK: - Sentence Splitting

    /// Splits text into sentence ranges using NSLinguisticTagger-style enumeration
    static func computeSentenceRanges(from text: String) -> [NSRange] {
        var ranges: [NSRange] = []
        let nsText = text as NSString

        nsText.enumerateSubstrings(
            in: NSRange(location: 0, length: nsText.length),
            options: .bySentences
        ) { _, substringRange, _, _ in
            if substringRange.length > 0 {
                ranges.append(substringRange)
            }
        }

        // Fallback: if no sentences detected, split by newlines
        if ranges.isEmpty {
            text.enumerateSubstrings(in: text.startIndex..., options: .byLines) { _, range, _, _ in
                let nsRange = NSRange(range, in: text)
                if nsRange.length > 0 {
                    ranges.append(nsRange)
                }
            }
        }

        // Final fallback: whole text as one range
        if ranges.isEmpty && !text.isEmpty {
            ranges.append(NSRange(location: 0, length: nsText.length))
        }

        return ranges
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
            sentenceRanges = []
            totalTextLength = 0
            state = .idle
            onComplete?()
        }
    }
}
