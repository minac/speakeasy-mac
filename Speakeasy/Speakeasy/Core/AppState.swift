import SwiftUI

@MainActor
class AppState: ObservableObject {
    // Published state
    @Published var playbackState: PlaybackState = .idle
    @Published var currentText: String = ""
    @Published var settings: SpeechSettings

    // Window visibility
    @Published var showInputWindow = false
    @Published var showSettingsWindow = false

    // Services
    private let speechEngine: SpeechEngine
    private let textExtractor: TextExtractor
    private let settingsService: SettingsService
    private let voiceDiscovery: VoiceDiscoveryService

    // Available voices
    @Published var availableVoices: [Voice] = []

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

    // MARK: - Speech Control

    func speak(text: String) async {
        guard !text.isEmpty else { return }

        do {
            // Extract text from URL if needed
            let textToSpeak: String
            if text.isValidURL {
                textToSpeak = try await textExtractor.extractText(from: text)
            } else {
                textToSpeak = text
            }

            currentText = textToSpeak

            // Speak with current settings
            try await speechEngine.speak(
                text: textToSpeak,
                voiceIdentifier: settings.selectedVoiceIdentifier,
                rate: settings.speechRate
            )
        } catch {
            print("Error speaking text: \(error.localizedDescription)")
            // TODO: Show error to user in Phase 7
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
        speechEngine.onProgress = { progress, total in
            // TODO: Update progress UI in Phase 7
        }

        speechEngine.onComplete = { [weak self] in
            Task { @MainActor [weak self] in
                self?.currentText = ""
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
