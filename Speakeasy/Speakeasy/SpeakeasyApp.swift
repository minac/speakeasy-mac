import SwiftUI

@main
struct SpeakeasyApp: App {
    var body: some Scene {
        // Placeholder - will implement full UI in Phase 3
        MenuBarExtra("Speakeasy", systemImage: "speaker.wave.2") {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
