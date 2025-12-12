import AVFoundation

class VoiceDiscoveryService {
    /// Discovers all available system voices
    func discoverVoices() -> [Voice] {
        AVSpeechSynthesisVoice.speechVoices()
            .map { Voice(from: $0) }
            .sorted { $0.name < $1.name }
    }

    /// Discovers voices filtered by language code (e.g., "en-US", "en")
    func discoverVoices(forLanguage languageCode: String) -> [Voice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(languageCode) }
            .map { Voice(from: $0) }
            .sorted { $0.name < $1.name }
    }

    /// Discovers high-quality voices only
    func discoverHighQualityVoices() -> [Voice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.quality == .enhanced || $0.quality == .premium }
            .map { Voice(from: $0) }
            .sorted { $0.name < $1.name }
    }

    /// Gets a specific voice by identifier
    func voice(withIdentifier identifier: String) -> Voice? {
        guard let avVoice = AVSpeechSynthesisVoice(identifier: identifier) else {
            return nil
        }
        return Voice(from: avVoice)
    }

    /// Gets the default voice for a language
    func defaultVoice(forLanguage languageCode: String) -> Voice? {
        guard let avVoice = AVSpeechSynthesisVoice(language: languageCode) else {
            return nil
        }
        return Voice(from: avVoice)
    }
}
