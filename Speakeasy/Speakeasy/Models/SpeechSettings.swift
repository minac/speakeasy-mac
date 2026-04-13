import Foundation

struct SpeechSettings: Codable {
    var selectedVoiceIdentifier: String
    var speechRate: Float  // 0.0 (slow) to 1.0 (fast) - AVSpeechSynthesizer range
    var showOnlyHighQualityVoices: Bool

    // TTS Engine selection
    var ttsEngine: TTSEngine

    // Google Cloud TTS settings (API key stored in Keychain, not here)
    var googleVoiceName: String      // e.g. "en-US-Neural2-A"
    var googleLanguageCode: String   // e.g. "en-US"

    static let `default` = SpeechSettings(
        selectedVoiceIdentifier: "com.apple.voice.compact.en-US.Samantha",
        speechRate: 0.5, // Normal speed (maps to 1.0x in UI)
        showOnlyHighQualityVoices: false,
        ttsEngine: .system,
        googleVoiceName: "en-US-Neural2-D",
        googleLanguageCode: "en-US"
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

    /// Converts UI speed (0.5x - 2.0x) to Google Cloud TTS speaking rate (0.5 - 2.0)
    /// Google's speakingRate maps directly to the UI multiplier
    static func uiSpeedToGoogleRate(_ uiSpeed: Float) -> Float {
        return max(0.5, min(2.0, uiSpeed))
    }

    var uiSpeed: Float {
        Self.rateToUISpeed(speechRate)
    }

    mutating func setUISpeed(_ speed: Float) {
        self.speechRate = Self.uiSpeedToRate(speed)
    }
}
