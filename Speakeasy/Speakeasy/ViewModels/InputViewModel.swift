import SwiftUI

@MainActor
class InputViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    /// Plays the input text or extracts and plays text from URL
    func play() async {
        guard !inputText.isEmpty else { return }

        // Clear previous error
        errorMessage = nil
        isProcessing = true

        defer {
            isProcessing = false
        }

        // AppState handles URL extraction and errors internally
        await appState.speak(text: inputText)
    }

    /// Stops current playback
    func stop() {
        appState.stop()
    }

    /// Clears the input text
    func clear() {
        inputText = ""
        errorMessage = nil
    }
}
