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
    @Published var showPermissionsAlert = false

    // Services
    private let speechEngine: SpeechEngine
    private let textExtractor: TextExtractor
    private let settingsService: SettingsService
    private let voiceDiscovery: VoiceDiscoveryService
    private let shortcutManager: ShortcutManager

    // Available voices
    @Published var availableVoices: [Voice] = []

    init() {
        self.settingsService = SettingsService()
        self.settings = settingsService.loadSettings()
        self.speechEngine = SpeechEngine()
        self.textExtractor = TextExtractor()
        self.voiceDiscovery = VoiceDiscoveryService()
        self.shortcutManager = ShortcutManager()

        setupSpeechCallbacks()
        loadVoices()
        setupGlobalShortcuts()
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

        // Clear previous errors
        errorMessage = nil

        do {
            // Extract text from URL if needed
            let textToSpeak: String
            if text.isValidURL {
                do {
                    textToSpeak = try await textExtractor.extractText(from: text)
                } catch {
                    errorMessage = "Failed to extract text from URL: \(error.localizedDescription)"
                    return
                }

                // Check for empty extracted text
                guard !textToSpeak.isEmpty else {
                    errorMessage = "No readable text found at URL"
                    return
                }
            } else {
                textToSpeak = text
            }

            currentText = textToSpeak

            // Speak with current settings
            do {
                try await speechEngine.speak(
                    text: textToSpeak,
                    voiceIdentifier: settings.selectedVoiceIdentifier,
                    rate: settings.speechRate
                )
            } catch {
                errorMessage = "Failed to speak text: \(error.localizedDescription)"
            }
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
                self?.currentWordRange = wordRange
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

    // MARK: - Global Shortcuts

    private func setupGlobalShortcuts() {
        // Check for accessibility permissions
        guard PermissionsManager.hasAccessibilityPermissions() else {
            AppLogger.shortcuts.warning("Accessibility permissions not granted. Global shortcuts disabled.")
            // Show alert after a brief delay to let the app finish launching
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                showPermissionsAlert = true
            }
            return
        }

        // Register the "Read Text" shortcut from settings
        let shortcut = settings.shortcuts.readTextShortcut
        shortcutManager.register(shortcut: shortcut) { [weak self] in
            Task { @MainActor [weak self] in
                self?.openInputWindow()
            }
        }
    }

    /// Re-registers global shortcuts (call after settings change)
    func updateGlobalShortcuts() {
        shortcutManager.unregisterAll()
        setupGlobalShortcuts()
    }
}
