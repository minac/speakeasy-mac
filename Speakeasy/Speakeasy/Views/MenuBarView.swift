import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Playback status (if active)
            if appState.playbackState != .idle {
                playbackSection
                Divider()
            }

            // Main actions
            Button("Read Text...") {
                openWindow(id: "input")
            }

            Button("Settings...") {
                openWindow(id: "settings")
            }

            Divider()

            Button("Quit Speakeasy") {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(width: 220)
    }

    @ViewBuilder
    private var playbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: playbackIcon)
                    .foregroundColor(playbackColor)
                Text(playbackStateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            // Progress indicator
            if appState.playbackState == .speaking {
                HStack {
                    Text("\(Int(appState.speechProgress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                ProgressView(value: appState.speechProgress)
                    .progressViewStyle(.linear)
            }

            HStack(spacing: 12) {
                if appState.playbackState == .speaking {
                    Button {
                        appState.pause()
                    } label: {
                        Image(systemName: "pause.fill")
                    }
                    .buttonStyle(.plain)
                } else if appState.playbackState == .paused {
                    Button {
                        appState.resume()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    appState.stop()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

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

    private var playbackStateText: String {
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
