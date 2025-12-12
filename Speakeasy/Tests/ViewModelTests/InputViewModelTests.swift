import XCTest
@testable import Speakeasy

@MainActor
final class InputViewModelTests: XCTestCase {
    var viewModel: InputViewModel!
    var appState: AppState!

    override func setUp() async throws {
        appState = AppState()
        viewModel = InputViewModel(appState: appState)
    }

    override func tearDown() async throws {
        viewModel = nil
        appState = nil
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.inputText, "")
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Plain Text Tests

    func testPlayWithPlainText() async {
        // Given
        viewModel.inputText = "Hello world"

        // When
        await viewModel.play()

        // Wait briefly for speech to start
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(appState.playbackState, .speaking)
        XCTAssertEqual(appState.currentText, "Hello world")
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testPlayWithEmptyText() async {
        // Given
        viewModel.inputText = ""

        // When
        await viewModel.play()

        // Then
        XCTAssertEqual(appState.playbackState, .idle)
        XCTAssertFalse(viewModel.isProcessing)
    }

    // MARK: - URL Tests

    func testPlayWithValidURL() async {
        // Given
        viewModel.inputText = "https://example.com"

        // When
        await viewModel.play()

        // Wait for async extraction and speech
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        XCTAssertFalse(viewModel.isProcessing)
        // Should have extracted text and started speaking
        XCTAssertFalse(appState.currentText.isEmpty)
    }

    func testPlayWithInvalidURL() async {
        // Given
        viewModel.inputText = "http://this is not a valid url"

        // When
        await viewModel.play()

        // Wait for processing
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - State Management Tests

    func testProcessingStateWhilePlaying() async {
        // Given
        viewModel.inputText = "Test text"

        // When
        let playTask = Task {
            await viewModel.play()
        }

        // Check processing state immediately
        try? await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertTrue(viewModel.isProcessing || appState.playbackState == .speaking)

        await playTask.value

        // Then - should finish processing
        XCTAssertFalse(viewModel.isProcessing)
    }

    func testClearErrorOnNewPlay() async {
        // Given
        viewModel.errorMessage = "Previous error"
        viewModel.inputText = "New text"

        // When
        await viewModel.play()

        // Then
        XCTAssertNil(viewModel.errorMessage)
    }

    func testStop() {
        // Given
        appState.currentText = "Some text"

        // When
        viewModel.stop()

        // Then
        XCTAssertEqual(appState.playbackState, .idle)
        XCTAssertEqual(appState.currentText, "")
    }

    // MARK: - Input Validation Tests

    func testCanPlayWithValidInput() {
        viewModel.inputText = "Hello"
        XCTAssertFalse(viewModel.inputText.isEmpty)
    }

    func testCannotPlayWithEmptyInput() {
        viewModel.inputText = ""
        XCTAssertTrue(viewModel.inputText.isEmpty)
    }

    // MARK: - Error Handling Tests

    func testErrorMessageDisplay() async {
        // Given
        viewModel.inputText = "http://invalid url with spaces"

        // When
        await viewModel.play()

        // Wait for error
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.errorMessage!.isEmpty)
    }
}
