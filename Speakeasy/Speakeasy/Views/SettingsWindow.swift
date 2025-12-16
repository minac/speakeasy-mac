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
        viewModel.uiSpeed != SpeechSettings.default.uiSpeed
    }

    private func restoreDefaults() {
        viewModel.selectedVoiceIdentifier = SpeechSettings.default.selectedVoiceIdentifier
        viewModel.uiSpeed = SpeechSettings.default.uiSpeed
    }
}
