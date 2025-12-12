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
                    VoicePicker(
                        voices: viewModel.availableVoices,
                        selectedVoiceIdentifier: $viewModel.selectedVoiceIdentifier
                    )
                }

                Section("Playback") {
                    SpeedSlider(speed: $viewModel.uiSpeed)
                }

                Section("Output") {
                    DirectoryPicker(directory: $viewModel.outputDirectory)
                }

                if viewModel.hasUnsavedChanges {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("You have unsaved changes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
        .frame(width: 500, height: 450)
        .onAppear {
            // Activate the window so it can receive keyboard input
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Helpers

    private var canRestoreDefaults: Bool {
        viewModel.selectedVoiceIdentifier != SpeechSettings.default.selectedVoiceIdentifier ||
        viewModel.uiSpeed != SpeechSettings.default.uiSpeed ||
        viewModel.outputDirectory != SpeechSettings.default.outputDirectory
    }

    private func restoreDefaults() {
        viewModel.selectedVoiceIdentifier = SpeechSettings.default.selectedVoiceIdentifier
        viewModel.uiSpeed = SpeechSettings.default.uiSpeed
        viewModel.outputDirectory = SpeechSettings.default.outputDirectory
    }
}
