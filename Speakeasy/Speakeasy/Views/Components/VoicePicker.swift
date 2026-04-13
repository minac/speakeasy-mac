import SwiftUI

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
        "\(voice.name) (\(voice.language)) - \(voice.qualityLabel)"
    }
}
