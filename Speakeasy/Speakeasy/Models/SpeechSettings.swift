import Foundation

struct SpeechSettings: Codable {
    var selectedVoiceIdentifier: String
    var speechRate: Float  // 0.0 (slow) to 1.0 (fast) - AVSpeechSynthesizer range

    static let `default` = SpeechSettings(
        selectedVoiceIdentifier: "com.apple.voice.compact.en-US.Samantha",
        speechRate: 0.5 // Normal speed (maps to 1.0x in UI)
    )
}

// MARK: - Speed conversion helpers
extension SpeechSettings {
    /// Converts UI speed (0.5x - 2.0x) to AVSpeechSynthesizer rate (0.0 - 1.0)
    static func uiSpeedToRate(_ uiSpeed: Float) -> Float {
        // UI: 0.5x = 0.0, 1.0x = 0.5, 2.0x = 1.0
        // Linear mapping: rate = (uiSpeed - 0.5) / 1.5
        return max(0.0, min(1.0, (uiSpeed - 0.5) / 1.5))
    }

    /// Converts AVSpeechSynthesizer rate (0.0 - 1.0) to UI speed (0.5x - 2.0x)
    static func rateToUISpeed(_ rate: Float) -> Float {
        // Inverse mapping: uiSpeed = rate * 1.5 + 0.5
        return rate * 1.5 + 0.5
    }

    var uiSpeed: Float {
        Self.rateToUISpeed(speechRate)
    }

    mutating func setUISpeed(_ speed: Float) {
        self.speechRate = Self.uiSpeedToRate(speed)
    }
}
