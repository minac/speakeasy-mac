import XCTest
@testable import Speakeasy

final class SettingsServiceTests: XCTestCase {
    var service: SettingsService!
    let testSuiteName = "SpeakeasyTestSettings"

    override func setUp() {
        // Use a separate UserDefaults suite for testing
        service = SettingsService(suiteName: testSuiteName)
    }

    override func tearDown() {
        // Clean up test data
        if let defaults = UserDefaults(suiteName: testSuiteName) {
            defaults.removePersistentDomain(forName: testSuiteName)
        }
        service = nil
    }

    func testLoadDefaultSettings() {
        // When
        let settings = service.loadSettings()

        // Then
        XCTAssertEqual(settings.selectedVoiceIdentifier, "com.apple.voice.compact.en-US.Samantha")
        XCTAssertEqual(settings.speechRate, 0.5)
        XCTAssertEqual(settings.shortcuts.readTextShortcut, "cmd+shift+p")
    }

    func testSaveAndLoadSettings() {
        // Given
        var settings = SpeechSettings.default
        settings.selectedVoiceIdentifier = "com.apple.voice.compact.en-US.Alex"
        settings.speechRate = 0.8
        settings.shortcuts.readTextShortcut = "cmd+shift+r"

        // When
        service.saveSettings(settings)
        let loadedSettings = service.loadSettings()

        // Then
        XCTAssertEqual(loadedSettings.selectedVoiceIdentifier, "com.apple.voice.compact.en-US.Alex")
        XCTAssertEqual(loadedSettings.speechRate, 0.8)
        XCTAssertEqual(loadedSettings.shortcuts.readTextShortcut, "cmd+shift+r")
    }

    func testSaveSettingsPersistsToUserDefaults() {
        // Given
        var settings = SpeechSettings.default
        settings.speechRate = 0.75

        // When
        service.saveSettings(settings)

        // Then
        let defaults = UserDefaults(suiteName: testSuiteName)!
        let data = defaults.data(forKey: "SpeakeasySettings")
        XCTAssertNotNil(data)

        let loadedSettings = try? JSONDecoder().decode(SpeechSettings.self, from: data!)
        XCTAssertEqual(loadedSettings?.speechRate, 0.75)
    }

    func testLoadSettingsWithCorruptedData() {
        // Given
        let defaults = UserDefaults(suiteName: testSuiteName)!
        defaults.set("corrupted data".data(using: .utf8), forKey: "SpeakeasySettings")

        // When
        let settings = service.loadSettings()

        // Then - should return default settings
        XCTAssertEqual(settings.selectedVoiceIdentifier, SpeechSettings.default.selectedVoiceIdentifier)
        XCTAssertEqual(settings.speechRate, SpeechSettings.default.speechRate)
    }

    func testOutputDirectoryPersistence() {
        // Given
        var settings = SpeechSettings.default
        let customDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        settings.outputDirectory = customDirectory

        // When
        service.saveSettings(settings)
        let loadedSettings = service.loadSettings()

        // Then
        XCTAssertEqual(loadedSettings.outputDirectory, customDirectory)
    }

    func testSpeedConversionRoundTrip() {
        // Test UI speed to rate and back
        let testSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

        for speed in testSpeeds {
            let rate = SpeechSettings.uiSpeedToRate(speed)
            let convertedSpeed = SpeechSettings.rateToUISpeed(rate)

            XCTAssertEqual(convertedSpeed, speed, accuracy: 0.01,
                          "Speed \(speed) should round-trip correctly")
        }
    }

    func testSpeedConversionBounds() {
        // Test boundary values
        XCTAssertEqual(SpeechSettings.uiSpeedToRate(0.5), 0.0, accuracy: 0.01)
        XCTAssertEqual(SpeechSettings.uiSpeedToRate(2.0), 1.0, accuracy: 0.01)
        XCTAssertEqual(SpeechSettings.uiSpeedToRate(1.0), 0.333, accuracy: 0.01)

        XCTAssertEqual(SpeechSettings.rateToUISpeed(0.0), 0.5, accuracy: 0.01)
        XCTAssertEqual(SpeechSettings.rateToUISpeed(1.0), 2.0, accuracy: 0.01)
    }
}
