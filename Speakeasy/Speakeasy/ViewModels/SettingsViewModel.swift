import SwiftUI
import AVFoundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var selectedVoiceIdentifier: String {
        didSet { checkForChanges() }
    }

    @Published var showOnlyHighQualityVoices: Bool {
        didSet { checkForChanges() }
    }

    @Published var ttsEngine: TTSEngine {
        didSet {
            checkForChanges()
            if ttsEngine == .googleCloud && googleVoices.isEmpty {
                fetchGoogleVoices()
            }
        }
    }

    @Published var googleCloudAPIKey: String {
        didSet { checkForChanges() }
    }

    @Published var googleVoiceName: String {
        didSet { checkForChanges() }
    }

    @Published var googleVoices: [Voice] = []
    @Published var isLoadingGoogleVoices = false
    @Published var googleVoiceError: String?

    private var _uiSpeed: Float = 1.0
    var uiSpeed: Float {
        get { _uiSpeed }
        set {
            let clamped = max(0.5, min(2.0, newValue))
            if _uiSpeed != clamped {
                objectWillChange.send()
                _uiSpeed = clamped
            }
            checkForChanges()
        }
    }

    @Published private(set) var hasUnsavedChanges: Bool = false

    var availableVoices: [Voice] {
        showOnlyHighQualityVoices ? highQualityVoices : allVoices
    }

    private let allVoices: [Voice]
    private let highQualityVoices: [Voice]
    private let appState: AppState
    private var originalSettings: SpeechSettings
    private var originalAPIKey: String
    private let voiceService = VoiceDiscoveryService()

    init(appState: AppState) {
        self.appState = appState
        self.originalSettings = appState.settings
        self.originalAPIKey = appState.googleCloudAPIKey

        // Load available system voices
        self.allVoices = voiceService.discoverVoices()
        self.highQualityVoices = voiceService.discoverHighQualityVoices()

        // Initialize from current settings
        self._uiSpeed = appState.settings.uiSpeed
        self.showOnlyHighQualityVoices = appState.settings.showOnlyHighQualityVoices
        self.ttsEngine = appState.settings.ttsEngine
        self.googleCloudAPIKey = appState.googleCloudAPIKey
        self.googleVoiceName = appState.settings.googleVoiceName

        // Ensure a valid system voice is selected
        let voices = appState.settings.showOnlyHighQualityVoices ? highQualityVoices : allVoices
        if voices.contains(where: { $0.id == appState.settings.selectedVoiceIdentifier }) {
            self.selectedVoiceIdentifier = appState.settings.selectedVoiceIdentifier
        } else {
            self.selectedVoiceIdentifier = voices.first?.id ?? allVoices.first?.id ?? ""
        }

        // Load cached Google voices from AppState
        self.googleVoices = appState.googleVoices
    }

    /// Fetch Google voices using the current API key
    func fetchGoogleVoices() {
        guard !googleCloudAPIKey.isEmpty else {
            googleVoices = []
            googleVoiceError = nil
            return
        }

        isLoadingGoogleVoices = true
        googleVoiceError = nil

        Task {
            do {
                let voices = try await appState.googleTTS.listVoices(
                    apiKey: googleCloudAPIKey,
                    languageCode: "en"
                )
                self.googleVoices = voices
                self.isLoadingGoogleVoices = false

                // Select first voice if current selection is not in list
                if !voices.contains(where: { $0.id == googleVoiceName }) {
                    if let first = voices.first {
                        googleVoiceName = first.id
                    }
                }
            } catch {
                self.googleVoices = []
                self.googleVoiceError = error.localizedDescription
                self.isLoadingGoogleVoices = false
            }
        }
    }

    /// Save settings to AppState
    func save() {
        var newSettings = appState.settings
        newSettings.selectedVoiceIdentifier = selectedVoiceIdentifier
        newSettings.setUISpeed(uiSpeed)
        newSettings.showOnlyHighQualityVoices = showOnlyHighQualityVoices
        newSettings.ttsEngine = ttsEngine
        newSettings.googleVoiceName = googleVoiceName

        // Derive language code from selected Google voice name
        if ttsEngine == .googleCloud {
            let parts = googleVoiceName.split(separator: "-")
            if parts.count >= 2 {
                newSettings.googleLanguageCode = "\(parts[0])-\(parts[1])"
            }
        }

        appState.settings = newSettings
        appState.saveSettings()
        appState.googleVoices = googleVoices

        // Save API key to Keychain
        appState.googleCloudAPIKey = googleCloudAPIKey

        originalSettings = newSettings
        originalAPIKey = googleCloudAPIKey
        hasUnsavedChanges = false
    }

    /// Cancel changes and revert to original settings
    func cancel() {
        selectedVoiceIdentifier = originalSettings.selectedVoiceIdentifier
        uiSpeed = originalSettings.uiSpeed
        showOnlyHighQualityVoices = originalSettings.showOnlyHighQualityVoices
        ttsEngine = originalSettings.ttsEngine
        googleCloudAPIKey = originalAPIKey
        googleVoiceName = originalSettings.googleVoiceName
        googleVoices = appState.googleVoices
        hasUnsavedChanges = false
    }

    // MARK: - Computed Properties

    var currentVoiceName: String {
        if ttsEngine == .googleCloud {
            return googleVoices.first { $0.id == googleVoiceName }?.name ?? googleVoiceName
        }
        return availableVoices.first { $0.id == selectedVoiceIdentifier }?.name ?? "Default"
    }

    var speedDisplayText: String {
        String(format: "%.1fx", uiSpeed)
    }

    // MARK: - Private Helpers

    private func checkForChanges() {
        hasUnsavedChanges = (
            selectedVoiceIdentifier != originalSettings.selectedVoiceIdentifier ||
            uiSpeed != originalSettings.uiSpeed ||
            showOnlyHighQualityVoices != originalSettings.showOnlyHighQualityVoices ||
            ttsEngine != originalSettings.ttsEngine ||
            googleCloudAPIKey != originalAPIKey ||
            googleVoiceName != originalSettings.googleVoiceName
        )
    }
}
