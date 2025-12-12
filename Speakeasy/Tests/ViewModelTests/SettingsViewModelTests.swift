import XCTest
@testable import Speakeasy

@MainActor
final class SettingsViewModelTests: XCTestCase {
    var viewModel: SettingsViewModel!
    var appState: AppState!

    override func setUp() async throws {
        appState = AppState()
        viewModel = SettingsViewModel(appState: appState)
    }

    override func tearDown() async throws {
        viewModel = nil
        appState = nil
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        // Should load settings from AppState
        XCTAssertEqual(viewModel.selectedVoiceIdentifier, appState.settings.selectedVoiceIdentifier)
        XCTAssertEqual(viewModel.uiSpeed, appState.settings.uiSpeed)
        XCTAssertEqual(viewModel.outputDirectory, appState.settings.outputDirectory)
        XCTAssertFalse(viewModel.hasUnsavedChanges)
    }

    func testAvailableVoices() {
        // Should have at least one voice available
        XCTAssertFalse(viewModel.availableVoices.isEmpty)
    }

    // MARK: - Voice Selection Tests

    func testChangeVoice() {
        // Given
        let originalVoice = viewModel.selectedVoiceIdentifier
        let voices = viewModel.availableVoices
        guard voices.count > 1 else {
            XCTFail("Need at least 2 voices for this test")
            return
        }

        // Find a different voice
        let newVoice = voices.first { $0.id != originalVoice }!

        // When
        viewModel.selectedVoiceIdentifier = newVoice.id

        // Then
        XCTAssertNotEqual(viewModel.selectedVoiceIdentifier, originalVoice)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    // MARK: - Speed Tests

    func testChangeSpeed() {
        // Given
        let originalSpeed = viewModel.uiSpeed

        // When
        viewModel.uiSpeed = 1.5

        // Then
        XCTAssertNotEqual(viewModel.uiSpeed, originalSpeed)
        XCTAssertEqual(viewModel.uiSpeed, 1.5)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    func testSpeedBounds() {
        // Test minimum
        viewModel.uiSpeed = 0.3 // Below minimum
        XCTAssertGreaterThanOrEqual(viewModel.uiSpeed, 0.5)

        // Test maximum
        viewModel.uiSpeed = 2.5 // Above maximum
        XCTAssertLessThanOrEqual(viewModel.uiSpeed, 2.0)

        // Test valid range
        viewModel.uiSpeed = 1.0
        XCTAssertEqual(viewModel.uiSpeed, 1.0)
    }

    // MARK: - Output Directory Tests

    func testChangeOutputDirectory() {
        // Given
        let originalDirectory = viewModel.outputDirectory
        let newDirectory = FileManager.default.temporaryDirectory

        // When
        viewModel.outputDirectory = newDirectory

        // Then
        XCTAssertNotEqual(viewModel.outputDirectory, originalDirectory)
        XCTAssertEqual(viewModel.outputDirectory, newDirectory)
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    // MARK: - Save Tests

    func testSaveSettings() {
        // Given
        let newSpeed: Float = 1.5
        viewModel.uiSpeed = newSpeed
        XCTAssertTrue(viewModel.hasUnsavedChanges)

        // When
        viewModel.save()

        // Then
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertEqual(appState.settings.uiSpeed, newSpeed)
    }

    func testSaveMultipleSettings() {
        // Given
        let voices = viewModel.availableVoices
        guard let newVoice = voices.first(where: { $0.id != viewModel.selectedVoiceIdentifier }) else {
            XCTFail("Need at least 2 voices")
            return
        }

        viewModel.selectedVoiceIdentifier = newVoice.id
        viewModel.uiSpeed = 1.75
        viewModel.outputDirectory = FileManager.default.temporaryDirectory

        // When
        viewModel.save()

        // Then
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertEqual(appState.settings.selectedVoiceIdentifier, newVoice.id)
        XCTAssertEqual(appState.settings.uiSpeed, 1.75)
        XCTAssertEqual(appState.settings.outputDirectory, FileManager.default.temporaryDirectory)
    }

    // MARK: - Cancel Tests

    func testCancelChanges() {
        // Given
        let originalVoice = viewModel.selectedVoiceIdentifier
        let originalSpeed = viewModel.uiSpeed
        let originalDirectory = viewModel.outputDirectory

        // Make changes
        viewModel.uiSpeed = 1.5
        XCTAssertTrue(viewModel.hasUnsavedChanges)

        // When
        viewModel.cancel()

        // Then
        XCTAssertFalse(viewModel.hasUnsavedChanges)
        XCTAssertEqual(viewModel.selectedVoiceIdentifier, originalVoice)
        XCTAssertEqual(viewModel.uiSpeed, originalSpeed)
        XCTAssertEqual(viewModel.outputDirectory, originalDirectory)
    }

    // MARK: - Validation Tests

    func testCurrentVoiceName() {
        // Should return a non-empty name for the current voice
        XCTAssertFalse(viewModel.currentVoiceName.isEmpty)
    }

    func testSpeedDisplayText() {
        viewModel.uiSpeed = 1.0
        XCTAssertEqual(viewModel.speedDisplayText, "1.0x")

        viewModel.uiSpeed = 1.5
        XCTAssertEqual(viewModel.speedDisplayText, "1.5x")
    }
}
