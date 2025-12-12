import XCTest
import AVFoundation
@testable import Speakeasy

@MainActor
final class SpeechEngineTests: XCTestCase {
    var engine: SpeechEngine!

    override func setUp() async throws {
        engine = SpeechEngine()
    }

    override func tearDown() async throws {
        engine.stop()
        engine = nil
    }

    func testSpeakWithText() async throws {
        // Given
        let text = "Hello world"
        let expectation = XCTestExpectation(description: "Speech starts")

        // When
        try await engine.speak(text: text, voiceIdentifier: nil, rate: 0.5)

        // Then
        XCTAssertEqual(engine.state, .speaking)
        expectation.fulfill()

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testSpeakCompletesSuccessfully() async throws {
        // Given
        let text = "Test"
        let expectation = XCTestExpectation(description: "Speech completes")

        engine.onComplete = {
            expectation.fulfill()
        }

        // When
        try await engine.speak(text: text, voiceIdentifier: nil, rate: 1.0)  // Faster rate for quick test

        // Then
        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertEqual(engine.state, .idle)
    }

    func testPauseSpeech() async throws {
        // Given
        let text = "This is a longer text for testing pause functionality"
        try await engine.speak(text: text, voiceIdentifier: nil, rate: 0.3)

        // Small delay to ensure speech has started
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // When
        engine.pause()

        // Then
        XCTAssertEqual(engine.state, .paused)
    }

    func testResumeSpeech() async throws {
        // Given
        let text = "This is a longer text for testing resume functionality"
        try await engine.speak(text: text, voiceIdentifier: nil, rate: 0.3)
        try await Task.sleep(nanoseconds: 100_000_000)
        engine.pause()

        // When
        engine.resume()

        // Then
        XCTAssertEqual(engine.state, .speaking)
    }

    func testStopSpeech() async throws {
        // Given
        let text = "This is text for testing stop functionality"
        try await engine.speak(text: text, voiceIdentifier: nil, rate: 0.3)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When
        engine.stop()

        // Then
        XCTAssertEqual(engine.state, .idle)
    }

    func testProgressCallback() async throws {
        // Given
        let text = "Hello world"
        var progressCalled = false
        let expectation = XCTestExpectation(description: "Progress callback called")

        engine.onProgress = { progress, total in
            progressCalled = true
            XCTAssertGreaterThan(total, 0)
            XCTAssertGreaterThanOrEqual(progress, 0.0)
            XCTAssertLessThanOrEqual(progress, 1.0)
            expectation.fulfill()
        }

        // When
        try await engine.speak(text: text, voiceIdentifier: nil, rate: 0.8)

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(progressCalled)
    }

    func testSpeakWithSpecificVoice() async throws {
        // Given
        let text = "Testing specific voice"
        let voiceID = "com.apple.voice.compact.en-US.Samantha"

        // When
        try await engine.speak(text: text, voiceIdentifier: voiceID, rate: 0.5)

        // Then
        XCTAssertEqual(engine.state, .speaking)
    }

    func testMultipleStopsAreIdempotent() {
        // Given
        engine.stop()

        // When
        engine.stop()
        engine.stop()

        // Then
        XCTAssertEqual(engine.state, .idle)
    }
}
