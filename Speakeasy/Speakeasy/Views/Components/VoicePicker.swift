import SwiftUI
import AVFoundation

struct VoicePicker: View {
    let voices: [Voice]
    @Binding var selectedVoiceIdentifier: String

    var body: some View {
        Picker("Voice", selection: $selectedVoiceIdentifier) {
            ForEach(voices) { voice in
                Text(voiceDisplayName(voice))
                    .tag(voice.id)
            }
        }
        .pickerStyle(.menu)
    }

    // MARK: - Helpers

    private func voiceDisplayName(_ voice: Voice) -> String {
        // Format: "Samantha (en-US) - Enhanced"
        let qualityText = qualityDescription(voice.quality)
        return "\(voice.name) (\(voice.language)) - \(qualityText)"
    }

    private func qualityDescription(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .default:
            return "Default"
        case .enhanced:
            return "Enhanced"
        case .premium:
            return "Premium"
        @unknown default:
            return "Unknown"
        }
    }
}
