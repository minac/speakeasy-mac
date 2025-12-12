import SwiftUI

struct InputWindow: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: InputViewModel
    @Environment(\.dismiss) var dismiss

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: InputViewModel(appState: appState))
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Enter text or URL:")
                    .font(.headline)
                Spacer()
            }

            // Text input area
            ZStack(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text("Paste a URL or type text to read aloud...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $viewModel.inputText)
                    .font(.body)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }

            // Error message
            if let error = appState.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
            }

            // Playback status
            if appState.playbackState != .idle {
                HStack {
                    Image(systemName: playbackIcon)
                        .foregroundColor(playbackColor)
                    Text(playbackStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            // Progress bar (when speaking)
            if appState.playbackState == .speaking {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(appState.speechProgress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    ProgressView(value: appState.speechProgress)
                        .progressViewStyle(.linear)
                }
            }

            // Action buttons
            HStack {
                // Clear button
                Button("Clear") {
                    viewModel.clear()
                }
                .keyboardShortcut("k", modifiers: [.command])
                .disabled(viewModel.inputText.isEmpty)

                Spacer()

                // Stop button (when playing)
                if appState.playbackState != .idle {
                    Button {
                        viewModel.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .keyboardShortcut(".", modifiers: [.command])
                }

                // Close button
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                // Play button
                Button {
                    Task {
                        await viewModel.play()
                    }
                } label: {
                    if viewModel.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                    } else {
                        Label("Play", systemImage: "play.fill")
                    }
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 600, height: 300)
        .onAppear {
            // Focus on text editor when window appears
            // Note: TextEditor auto-focuses in SwiftUI
        }
    }

    // MARK: - Helpers

    private var playbackIcon: String {
        switch appState.playbackState {
        case .idle:
            return "speaker.wave.2"
        case .speaking:
            return "speaker.wave.2.fill"
        case .paused:
            return "pause.circle.fill"
        }
    }

    private var playbackColor: Color {
        switch appState.playbackState {
        case .idle:
            return .secondary
        case .speaking:
            return .blue
        case .paused:
            return .orange
        }
    }

    private var playbackStatusText: String {
        switch appState.playbackState {
        case .idle:
            return "Ready"
        case .speaking:
            return "Speaking..."
        case .paused:
            return "Paused"
        }
    }
}
