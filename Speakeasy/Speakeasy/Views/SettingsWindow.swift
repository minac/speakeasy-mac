import SwiftUI

struct SettingsWindow: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) var dismiss

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(appState: appState))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()

            Divider()

            // Settings form
            Form {
                Section("Engine") {
                    Picker("TTS Engine", selection: $viewModel.ttsEngine) {
                        ForEach(TTSEngine.allCases, id: \.self) { engine in
                            Text(engine.displayName).tag(engine)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if viewModel.ttsEngine == .system {
                    systemVoiceSection
                } else {
                    googleCloudSection
                }

                Section("Playback") {
                    SpeedSlider(speed: $viewModel.uiSpeed)
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight: .infinity)

            Divider()

            // Footer buttons
            HStack {
                Button("Restore Defaults") {
                    restoreDefaults()
                }
                .disabled(!canRestoreDefaults)

                Spacer()

                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.orange)
                    .opacity(viewModel.hasUnsavedChanges ? 1 : 0)

                Button("Cancel") {
                    viewModel.cancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    viewModel.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!viewModel.hasUnsavedChanges)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 420)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)

            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.title == "Settings" }),
                   let screen = NSScreen.main {
                    let screenFrame = screen.visibleFrame
                    let windowFrame = window.frame
                    let x = screenFrame.maxX - windowFrame.width - 20
                    let y = screenFrame.maxY - windowFrame.height - 20
                    window.setFrameOrigin(NSPoint(x: x, y: y))
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    // MARK: - System Voice Section

    @ViewBuilder
    private var systemVoiceSection: some View {
        Section("Voice") {
            HStack {
                VoicePicker(
                    voices: viewModel.availableVoices,
                    selectedVoiceIdentifier: $viewModel.selectedVoiceIdentifier
                )

                Spacer()

                Toggle("Premium only", isOn: Binding(
                    get: { viewModel.showOnlyHighQualityVoices },
                    set: { newValue in
                        viewModel.showOnlyHighQualityVoices = newValue
                        if let firstVoice = viewModel.availableVoices.first {
                            viewModel.selectedVoiceIdentifier = firstVoice.id
                        }
                    }
                ))
                .toggleStyle(.checkbox)
            }
        }
    }

    // MARK: - Google Cloud Section

    @ViewBuilder
    private var googleCloudSection: some View {
        Section("Google Cloud TTS") {
            SecureField("API Key", text: $viewModel.googleCloudAPIKey)
                .textFieldStyle(.roundedBorder)
                .onChange(of: viewModel.googleCloudAPIKey) {
                    // Debounce: fetch voices after key entry
                    if !viewModel.googleCloudAPIKey.isEmpty {
                        viewModel.fetchGoogleVoices()
                    }
                }

            if viewModel.isLoadingGoogleVoices {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading voices...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let error = viewModel.googleVoiceError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else if !viewModel.googleVoices.isEmpty {
                VoicePicker(
                    voices: viewModel.googleVoices,
                    selectedVoiceIdentifier: $viewModel.googleVoiceName
                )
            } else if !viewModel.googleCloudAPIKey.isEmpty {
                Text("Enter API key and press Return to load voices")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Enter your Google Cloud API key to get started")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private var canRestoreDefaults: Bool {
        viewModel.selectedVoiceIdentifier != SpeechSettings.default.selectedVoiceIdentifier ||
        viewModel.uiSpeed != SpeechSettings.default.uiSpeed ||
        viewModel.showOnlyHighQualityVoices != SpeechSettings.default.showOnlyHighQualityVoices ||
        viewModel.ttsEngine != SpeechSettings.default.ttsEngine ||
        !viewModel.googleCloudAPIKey.isEmpty ||
        viewModel.googleVoiceName != SpeechSettings.default.googleVoiceName
    }

    private func restoreDefaults() {
        viewModel.selectedVoiceIdentifier = SpeechSettings.default.selectedVoiceIdentifier
        viewModel.uiSpeed = SpeechSettings.default.uiSpeed
        viewModel.showOnlyHighQualityVoices = SpeechSettings.default.showOnlyHighQualityVoices
        viewModel.ttsEngine = SpeechSettings.default.ttsEngine
        viewModel.googleCloudAPIKey = ""
        viewModel.googleVoiceName = SpeechSettings.default.googleVoiceName
    }
}
