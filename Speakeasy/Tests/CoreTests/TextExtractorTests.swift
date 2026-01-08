import XCTest
@testable import Speakeasy

final class TextExtractorTests: XCTestCase {
    var extractor: TextExtractor!

    override func setUp() async throws {
        extractor = TextExtractor()
    }

    override func tearDown() async throws {
        extractor = nil
    }

    // MARK: - URL Validation Tests

    func testIsValidURL_WithHTTPS() {
        XCTAssertTrue("https://example.com".isValidURL)
    }

    func testIsValidURL_WithHTTP() {
        XCTAssertTrue("http://example.com".isValidURL)
    }

    func testIsValidURL_WithWWW() {
        XCTAssertTrue("www.example.com".isValidURL)
    }

    func testIsValidURL_PlainText() {
        XCTAssertFalse("This is plain text".isValidURL)
    }

    func testIsValidURL_Empty() {
        XCTAssertFalse("".isValidURL)
    }

    func testAddingHTTPSIfNeeded_AlreadyHTTPS() {
        XCTAssertEqual("https://example.com".addingHTTPSIfNeeded(), "https://example.com")
    }

    func testAddingHTTPSIfNeeded_HTTP() {
        XCTAssertEqual("http://example.com".addingHTTPSIfNeeded(), "http://example.com")
    }

    func testAddingHTTPSIfNeeded_WWW() {
        XCTAssertEqual("www.example.com".addingHTTPSIfNeeded(), "https://www.example.com")
    }

    func testAddingHTTPSIfNeeded_PlainText() {
        XCTAssertNil("plain text".addingHTTPSIfNeeded())
    }

    // MARK: - Text Extraction Tests

    func testExtractText_PlainText() async throws {
        // Given
        let text = "This is plain text without a URL"

        // When
        let result = try await extractor.extractText(from: text)

        // Then
        XCTAssertEqual(result, text)
    }

    func testExtractText_PlainTextPassthrough() async throws {
        // Given - text that looks like it might be a URL but isn't
        let plainText = "not a valid url"

        // When
        let result = try await extractor.extractText(from: plainText)

        // Then - should pass through as plain text
        XCTAssertEqual(result, plainText)
    }

    func testExtractText_MalformedURLWithHTTP() async throws {
        // Given - text with http but malformed
        let malformedURL = "http://this is not valid"

        // When/Then
        do {
            _ = try await extractor.extractText(from: malformedURL)
            XCTFail("Expected to throw an error")
        } catch {
            XCTAssertTrue(error is TextExtractor.ExtractionError)
        }
    }

    func testExtractText_EmptyString() async throws {
        // Given
        let empty = ""

        // When
        let result = try await extractor.extractText(from: empty)

        // Then
        XCTAssertEqual(result, "")
    }

    // MARK: - HTML Parsing Tests

    func testParseHTML_RemovesScriptTags() throws {
        // Given
        let html = "<html><body><p>Hello</p><script>alert('test')</script></body></html>"

        // When
        let result = try extractor.parseHTMLForTesting(html)

        // Then
        XCTAssertTrue(result.contains("Hello"))
        XCTAssertFalse(result.contains("alert"))
        XCTAssertFalse(result.contains("script"))
    }

    func testParseHTML_RemovesStyleTags() throws {
        // Given
        let html = "<html><body><p>Content</p><style>.class { color: red; }</style></body></html>"

        // When
        let result = try extractor.parseHTMLForTesting(html)

        // Then
        XCTAssertTrue(result.contains("Content"))
        XCTAssertFalse(result.contains("color"))
        XCTAssertFalse(result.contains("red"))
    }

    func testParseHTML_RemovesNavigation() throws {
        // Given
        let html = "<html><body><nav>Menu</nav><p>Article</p></body></html>"

        // When
        let result = try extractor.parseHTMLForTesting(html)

        // Then
        XCTAssertTrue(result.contains("Article"))
        XCTAssertFalse(result.contains("Menu"))
    }

    func testParseHTML_NormalizesWhitespace() throws {
        // Given
        let html = "<html><body><p>Word1    Word2\n\n\nWord3</p></body></html>"

        // When
        let result = try extractor.parseHTMLForTesting(html)

        // Then
        XCTAssertEqual(result, "Word1 Word2 Word3")
    }

    func testParseHTML_ExtractsMultipleParagraphs() throws {
        // Given
        let html = """
        <html><body>
            <p>First paragraph.</p>
            <p>Second paragraph.</p>
            <p>Third paragraph.</p>
        </body></html>
        """

        // When
        let result = try extractor.parseHTMLForTesting(html)

        // Then - paragraphs should be separated by double newlines
        XCTAssertEqual(result, "First paragraph.\n\nSecond paragraph.\n\nThird paragraph.")
    }

    func testParseHTML_HandlesEmptyHTML() throws {
        // Given
        let html = "<html><body></body></html>"

        // When
        let result = try extractor.parseHTMLForTesting(html)

        // Then
        XCTAssertEqual(result, "")
    }

    func testParseHTML_PreservesParagraphBreaks() throws {
        // Given
        let html = "<html><body><p>Line 1</p><br><p>Line 2</p></body></html>"

        // When
        let result = try extractor.parseHTMLForTesting(html)

        // Then - paragraphs should be separated by double newlines for speech pauses
        XCTAssertEqual(result, "Line 1\n\nLine 2")
    }

    func testParseHTML_PreservesHeadingsAndParagraphs() throws {
        // Given
        let html = """
        <html><body>
            <h1>Main Title</h1>
            <p>Introduction paragraph.</p>
            <h2>Section One</h2>
            <p>First section content.</p>
        </body></html>
        """

        // When
        let result = try extractor.parseHTMLForTesting(html)

        // Then - each block element should be separated by double newlines
        XCTAssertEqual(result, "Main Title\n\nIntroduction paragraph.\n\nSection One\n\nFirst section content.")
    }

    func testParseHTML_PreservesListItems() throws {
        // Given
        let html = """
        <html><body>
            <p>Here are the items:</p>
            <ul>
                <li>First item</li>
                <li>Second item</li>
                <li>Third item</li>
            </ul>
        </body></html>
        """

        // When
        let result = try extractor.parseHTMLForTesting(html)

        // Then - list items should be separate paragraphs
        XCTAssertTrue(result.contains("Here are the items:"))
        XCTAssertTrue(result.contains("First item\n\nSecond item\n\nThird item"))
    }

    // MARK: - Integration Tests (Network)
    // These tests require network access and may be slow

    func testExtractText_FromRealURL_Example() async throws {
        // Given
        let url = "https://example.com"

        // When
        let result = try await extractor.extractText(from: url)

        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("Example Domain"))
    }

    func testExtractText_Timeout() async throws {
        // Given
        let timeout: TimeInterval = 1
        let slowExtractor = TextExtractor(timeout: timeout)
        // Use a URL that's likely to timeout
        let url = "https://httpbin.org/delay/10"

        // When/Then
        do {
            _ = try await slowExtractor.extractText(from: url)
            XCTFail("Expected to throw an error")
        } catch {
            XCTAssertTrue(error is TextExtractor.ExtractionError || error is URLError)
        }
    }

    func testExtractText_HTTPError() async throws {
        // Given
        let url = "https://httpbin.org/status/404"

        // When/Then
        do {
            _ = try await extractor.extractText(from: url)
            XCTFail("Expected to throw an error")
        } catch {
            if let extractionError = error as? TextExtractor.ExtractionError,
               case .httpError(let statusCode) = extractionError {
                // httpbin.org may return 503 when overloaded, accept any 4xx/5xx
                XCTAssertTrue(statusCode >= 400, "Expected HTTP error status, got \(statusCode)")
            } else {
                XCTFail("Expected ExtractionError.httpError")
            }
        }
    }
}
