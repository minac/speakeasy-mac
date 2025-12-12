import Foundation

class SettingsService {
    private let userDefaults: UserDefaults
    private let settingsKey = "SpeakeasySettings"

    init(suiteName: String? = nil) {
        if let suiteName = suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        } else {
            self.userDefaults = UserDefaults.standard
        }
    }

    /// Loads settings from UserDefaults, returns default settings if none exist or data is corrupted
    func loadSettings() -> SpeechSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(SpeechSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    /// Saves settings to UserDefaults
    func saveSettings(_ settings: SpeechSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }

    /// Resets settings to default values
    func resetToDefaults() {
        userDefaults.removeObject(forKey: settingsKey)
    }
}
