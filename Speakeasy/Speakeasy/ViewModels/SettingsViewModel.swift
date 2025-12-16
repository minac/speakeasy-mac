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
    private let voiceService = VoiceDiscoveryService()

    init(appState: AppState) {
        self.appState = appState
        self.originalSettings = appState.settings

        // Load available voices first
        self.allVoices = voiceService.discoverVoices()
        self.highQualityVoices = voiceService.discoverHighQualityVoices()

        // Initialize from current settings
        self._uiSpeed = appState.settings.uiSpeed
        self.showOnlyHighQualityVoices = appState.settings.showOnlyHighQualityVoices

        // Ensure a valid voice is selected based on current filter
        let voices = appState.settings.showOnlyHighQualityVoices ? highQualityVoices : allVoices
        if voices.contains(where: { $0.id == appState.settings.selectedVoiceIdentifier }) {
            self.selectedVoiceIdentifier = appState.settings.selectedVoiceIdentifier
        } else {
            self.selectedVoiceIdentifier = voices.first?.id ?? allVoices.first?.id ?? ""
        }
    }

    /// Save settings to AppState
    func save() {
        var newSettings = appState.settings
        newSettings.selectedVoiceIdentifier = selectedVoiceIdentifier
        newSettings.setUISpeed(uiSpeed)
        newSettings.showOnlyHighQualityVoices = showOnlyHighQualityVoices

        appState.settings = newSettings
        appState.saveSettings()

        // Update original settings to reflect saved state
        originalSettings = newSettings
        hasUnsavedChanges = false
    }

    /// Cancel changes and revert to original settings
    func cancel() {
        selectedVoiceIdentifier = originalSettings.selectedVoiceIdentifier
        uiSpeed = originalSettings.uiSpeed
        showOnlyHighQualityVoices = originalSettings.showOnlyHighQualityVoices
        hasUnsavedChanges = false
    }

    // MARK: - Computed Properties

    var currentVoiceName: String {
        availableVoices.first { $0.id == selectedVoiceIdentifier }?.name ?? "Default"
    }

    var speedDisplayText: String {
        String(format: "%.1fx", uiSpeed)
    }

    // MARK: - Private Helpers

    private func checkForChanges() {
        hasUnsavedChanges = (
            selectedVoiceIdentifier != originalSettings.selectedVoiceIdentifier ||
            uiSpeed != originalSettings.uiSpeed ||
            showOnlyHighQualityVoices != originalSettings.showOnlyHighQualityVoices
        )
    }
}
