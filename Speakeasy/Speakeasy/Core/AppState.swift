import SwiftUI

@MainActor
class AppState: ObservableObject {
    // Published state
    @Published var playbackState: PlaybackState = .idle
    @Published var currentText: String = ""
    @Published var settings: SpeechSettings
    @Published var errorMessage: String?
    @Published var speechProgress: Double = 0.0
    @Published var currentWordRange: NSRange?

    // Window visibility
    @Published var showInputWindow = false
    @Published var showSettingsWindow = false

    // Services
    private let speechEngine: SpeechEngine
    private let textExtractor: TextExtractor
    private let settingsService: SettingsService
    private let voiceDiscovery: VoiceDiscoveryService
    let googleTTS = GoogleCloudTTSService()

    // Available voices
    @Published var availableVoices: [Voice] = []
    @Published var googleVoices: [Voice] = []
    @Published var isLoadingGoogleVoices = false

    init() {
        self.settingsService = SettingsService()
        self.settings = settingsService.loadSettings()
        self.speechEngine = SpeechEngine()
        self.textExtractor = TextExtractor()
        self.voiceDiscovery = VoiceDiscoveryService()

        setupSpeechCallbacks()
        loadVoices()
    }

    // MARK: - Voice Management

    private func loadVoices() {
        availableVoices = voiceDiscovery.discoverVoices()
    }

    var currentVoice: Voice? {
        voiceDiscovery.voice(withIdentifier: settings.selectedVoiceIdentifier)
    }

    /// Fetches Google Cloud voices if API key is set
    func loadGoogleVoices() async {
        guard !settings.googleCloudAPIKey.isEmpty else {
            googleVoices = []
            return
        }

        isLoadingGoogleVoices = true
        defer { isLoadingGoogleVoices = false }

        do {
            googleVoices = try await googleTTS.listVoices(
                apiKey: settings.googleCloudAPIKey,
                languageCode: "en"
            )
        } catch {
            log.error("Failed to fetch Google voices: \(error.localizedDescription)")
            googleVoices = []
        }
    }

    // MARK: - Speech Control

    func speak(text: String) async {
        guard !text.isEmpty else { return }

        errorMessage = nil

        // Extract text from URL if needed
        let textToSpeak: String
        if text.isValidURL {
            do {
                textToSpeak = try await textExtractor.extractText(from: text)
            } catch {
                errorMessage = "Failed to extract text from URL: \(error.localizedDescription)"
                return
            }

            guard !textToSpeak.isEmpty else {
                errorMessage = "No readable text found at URL"
                return
            }
        } else {
            textToSpeak = text
        }

        currentText = textToSpeak

        // Route to the appropriate TTS engine
        switch settings.ttsEngine {
        case .system:
            await speakWithSystem(text: textToSpeak)
        case .googleCloud:
            await speakWithGoogle(text: textToSpeak)
        }
    }

    private func speakWithSystem(text: String) async {
        do {
            try await speechEngine.speak(
                text: text,
                voiceIdentifier: settings.selectedVoiceIdentifier,
                rate: settings.speechRate
            )
        } catch {
            errorMessage = "Failed to speak text: \(error.localizedDescription)"
        }
    }

    private func speakWithGoogle(text: String) async {
        guard !settings.googleCloudAPIKey.isEmpty else {
            errorMessage = "Google Cloud API key is not configured. Add it in Settings."
            return
        }

        do {
            let uiSpeed = SpeechSettings.rateToUISpeed(settings.speechRate)
            let audioData = try await googleTTS.synthesize(
                text: text,
                voiceName: settings.googleVoiceName,
                languageCode: settings.googleLanguageCode,
                speakingRate: SpeechSettings.uiSpeedToGoogleRate(uiSpeed),
                apiKey: settings.googleCloudAPIKey
            )
            try speechEngine.playAudio(data: audioData)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pause() {
        speechEngine.pause()
    }

    func resume() {
        speechEngine.resume()
    }

    func stop() {
        speechEngine.stop()
        currentText = ""
        speechProgress = 0.0
        currentWordRange = nil
    }

    // MARK: - Settings Management

    func updateSettings(_ newSettings: SpeechSettings) {
        settings = newSettings
        settingsService.saveSettings(newSettings)
    }

    func saveSettings() {
        settingsService.saveSettings(settings)
    }

    // MARK: - Window Management

    func openInputWindow() {
        showInputWindow = true
    }

    func openSettingsWindow() {
        showSettingsWindow = true
    }

    // MARK: - Private Setup

    private func setupSpeechCallbacks() {
        speechEngine.onProgress = { [weak self] progress, wordRange in
            Task { @MainActor [weak self] in
                self?.speechProgress = progress
                // Only set word range if it's a valid range (system TTS)
                if wordRange.location != NSNotFound {
                    self?.currentWordRange = wordRange
                }
            }
        }

        speechEngine.onComplete = { [weak self] in
            Task { @MainActor [weak self] in
                self?.currentText = ""
                self?.speechProgress = 0.0
                self?.currentWordRange = nil
            }
        }

        // Observe playback state changes
        Task {
            for await state in speechEngine.$state.values {
                self.playbackState = state
            }
        }
    }

}
