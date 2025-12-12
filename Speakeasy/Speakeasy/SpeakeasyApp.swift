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

        // Input window
        Window("Read Text", id: "input") {
            InputWindow(appState: appState)
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .keyboardShortcut("r", modifiers: [.command])

        // Settings window
        Window("Settings", id: "settings") {
            SettingsWindow(appState: appState)
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .keyboardShortcut(",", modifiers: [.command])
    }
}

