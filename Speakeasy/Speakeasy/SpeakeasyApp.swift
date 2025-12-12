import SwiftUI

@main
struct SpeakeasyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menu bar app (macOS 13+)
        MenuBarExtra("Speakeasy", systemImage: "speaker.wave.2") {
            MenuBarView()
                .environmentObject(appState)
        }

        // Input window (will be implemented in Phase 4)
        Window("Read Text", id: "input") {
            PlaceholderInputWindow()
                .environmentObject(appState)
                .frame(width: 600, height: 300)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .keyboardShortcut("r", modifiers: [.command])

        // Settings window (will be implemented in Phase 5)
        Window("Settings", id: "settings") {
            PlaceholderSettingsWindow()
                .environmentObject(appState)
                .frame(width: 500, height: 400)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .keyboardShortcut(",", modifiers: [.command])
    }
}

// MARK: - Placeholder Views

struct PlaceholderInputWindow: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Text("Input Window")
                .font(.title)
            Text("Will be implemented in Phase 4")
                .foregroundColor(.secondary)
            Button("Close") {
                // Window will close automatically
            }
        }
        .padding()
    }
}

struct PlaceholderSettingsWindow: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings Window")
                .font(.title)
            Text("Will be implemented in Phase 5")
                .foregroundColor(.secondary)

            Form {
                LabeledContent("Voice") {
                    Text(appState.currentVoice?.name ?? "Default")
                }
                LabeledContent("Speed") {
                    Text(String(format: "%.1fx", appState.settings.uiSpeed))
                }
            }
            .formStyle(.grouped)

            Button("Close") {
                // Window will close automatically
            }
        }
        .padding()
    }
}
