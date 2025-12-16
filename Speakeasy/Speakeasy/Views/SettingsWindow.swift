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
        .frame(width: 500, height: 350)
        .onAppear {
            // Activate the app and position window at top right
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

    // MARK: - Helpers

    private var canRestoreDefaults: Bool {
        viewModel.selectedVoiceIdentifier != SpeechSettings.default.selectedVoiceIdentifier ||
        viewModel.uiSpeed != SpeechSettings.default.uiSpeed ||
        viewModel.showOnlyHighQualityVoices != SpeechSettings.default.showOnlyHighQualityVoices
    }

    private func restoreDefaults() {
        viewModel.selectedVoiceIdentifier = SpeechSettings.default.selectedVoiceIdentifier
        viewModel.uiSpeed = SpeechSettings.default.uiSpeed
        viewModel.showOnlyHighQualityVoices = SpeechSettings.default.showOnlyHighQualityVoices
    }
}
