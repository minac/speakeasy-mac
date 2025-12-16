import SwiftUI
import AVFoundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var selectedVoiceIdentifier: String {
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

    let availableVoices: [Voice]

    private let appState: AppState
    private var originalSettings: SpeechSettings
    private let voiceService = VoiceDiscoveryService()

    init(appState: AppState) {
        self.appState = appState
        self.originalSettings = appState.settings

        // Initialize from current settings
        self.selectedVoiceIdentifier = appState.settings.selectedVoiceIdentifier
        self._uiSpeed = appState.settings.uiSpeed

        // Load available voices
        self.availableVoices = voiceService.discoverVoices()
    }

    /// Save settings to AppState
    func save() {
        var newSettings = appState.settings
        newSettings.selectedVoiceIdentifier = selectedVoiceIdentifier
        newSettings.setUISpeed(uiSpeed)

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
            uiSpeed != originalSettings.uiSpeed
        )
    }
}
