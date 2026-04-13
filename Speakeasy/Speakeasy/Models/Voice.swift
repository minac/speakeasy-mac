import AVFoundation

struct Voice: Identifiable, Hashable {
    let id: String
    let name: String
    let language: String
    let qualityLabel: String

    var avVoice: AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice(identifier: id)
    }

    init(from avVoice: AVSpeechSynthesisVoice) {
        self.id = avVoice.identifier
        self.name = avVoice.name
        self.language = avVoice.language
        switch avVoice.quality {
        case .enhanced: self.qualityLabel = "Enhanced"
        case .premium: self.qualityLabel = "Premium"
        default: self.qualityLabel = "Default"
        }
    }

    init(googleName: String, languageCode: String, gender: String) {
        self.id = googleName
        self.name = Self.friendlyName(from: googleName)
        self.language = languageCode
        self.qualityLabel = gender.capitalized
    }

    /// Converts "en-US-Neural2-A" → "Neural2 A"
    private static func friendlyName(from googleName: String) -> String {
        let parts = googleName.split(separator: "-")
        guard parts.count >= 4 else { return googleName }
        let nameParts = parts.dropFirst(2)
        return nameParts.joined(separator: " ")
    }
}
