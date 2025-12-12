import SwiftUI
import AVFoundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var selectedVoiceIdentifier: String {
        didSet { checkForChanges() }
    }

    @Published var uiSpeed: Float {
        didSet {
            // Clamp to valid range
            uiSpeed = max(0.5, min(2.0, uiSpeed))
            checkForChanges()
        }
    }

    @Published var outputDirectory: URL {
        didSet { checkForChanges() }
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
        self.uiSpeed = appState.settings.uiSpeed
        self.outputDirectory = appState.settings.outputDirectory

        // Load available voices
        self.availableVoices = voiceService.discoverVoices()
    }

    /// Save settings to AppState
    func save() {
        var newSettings = appState.settings
        newSettings.selectedVoiceIdentifier = selectedVoiceIdentifier
        newSettings.setUISpeed(uiSpeed)
        newSettings.outputDirectory = outputDirectory

        appState.settings = newSettings
        appState.saveSettings()
        appState.updateGlobalShortcuts() // Re-register shortcuts with new settings

        // Update original settings to reflect saved state
        originalSettings = newSettings
        hasUnsavedChanges = false
    }

    /// Cancel changes and revert to original settings
    func cancel() {
        selectedVoiceIdentifier = originalSettings.selectedVoiceIdentifier
        uiSpeed = originalSettings.uiSpeed
        outputDirectory = originalSettings.outputDirectory
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
            outputDirectory != originalSettings.outputDirectory
        )
    }
}
