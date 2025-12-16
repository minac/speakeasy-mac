import SwiftUI

@main
struct SpeakeasyApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        // Menu bar app (macOS 13+)
        MenuBarExtra("Speakeasy", systemImage: "speaker.wave.2") {
            MenuBarView()
                .environmentObject(appState)
                .onChange(of: appState.showInputWindow) { _, newValue in
                    if newValue {
                        openWindow(id: "input")
                        appState.showInputWindow = false
                    }
                }
                .onChange(of: appState.showSettingsWindow) { _, newValue in
                    if newValue {
                        openWindow(id: "settings")
                        appState.showSettingsWindow = false
                    }
                }
        }

        // Input window
        Window("Read Text", id: "input") {
            InputWindow(appState: appState)
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)

        // Settings window
        Window("Settings", id: "settings") {
            SettingsWindow(appState: appState)
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)
    }
}

