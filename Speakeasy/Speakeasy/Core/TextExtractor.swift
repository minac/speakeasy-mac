import Foundation
import SwiftSoup

actor TextExtractor {
    enum ExtractionError: Error, LocalizedError {
        case invalidURL
        case httpError(Int)
        case parsingError(String)
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL format"
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .parsingError(let message):
                return "Parsing error: \(message)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }

    private let session: URLSession
    private let timeout: TimeInterval

    init(timeout: TimeInterval = 30) {
        self.timeout = timeout

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.httpAdditionalHeaders = [
            "User-Agent": "Speakeasy/1.0 (macOS)"
        ]
        self.session = URLSession(configuration: config)
    }

    /// Extracts text from a URL or returns plain text if not a URL
    func extractText(from input: String) async throws -> String {
        // Empty input returns empty string
        guard !input.isEmpty else {
            return ""
        }

        // Check if input is a URL
        guard input.isValidURL else {
            // If it's not a URL and not a plain text check, throw error
            // But if it looks like plain text (no URL pattern), return as-is
            if input.contains("http") || input.contains("www") {
                throw ExtractionError.invalidURL
            }
            return input
        }

        // Normalize URL
        guard let urlString = input.addingHTTPSIfNeeded(),
              let url = URL(string: urlString) else {
            throw ExtractionError.invalidURL
        }

        // Fetch content
        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ExtractionError.networkError(URLError(.badServerResponse))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw ExtractionError.httpError(httpResponse.statusCode)
            }

            // Detect content type
            let contentType = httpResponse.mimeType ?? ""

            if contentType.contains("text/html") {
                return try parseHTML(data)
            } else {
                // Plain text or other
                return String(data: data, encoding: .utf8) ?? ""
            }
        } catch let error as ExtractionError {
            throw error
        } catch {
            throw ExtractionError.networkError(error)
        }
    }

    /// Parses HTML and extracts clean text
    private func parseHTML(_ data: Data) throws -> String {
        guard let html = String(data: data, encoding: .utf8) else {
            throw ExtractionError.parsingError("Unable to decode HTML data")
        }

        return try parseHTMLString(html)
    }

    /// Parses HTML string and extracts clean text (exposed for testing)
    func parseHTMLString(_ html: String) throws -> String {
        do {
            let doc = try SwiftSoup.parse(html)

            // Remove unwanted elements
            try doc.select("script, style, nav, footer, aside, header").remove()

            // Extract text from body
            guard let body = doc.body() else {
                return ""
            }

            let text = try body.text()

            // Normalize whitespace
            return text.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        } catch {
            throw ExtractionError.parsingError(error.localizedDescription)
        }
    }
}

// MARK: - Testing Support
extension TextExtractor {
    /// Exposed for testing - parses HTML synchronously
    nonisolated func parseHTMLForTesting(_ html: String) throws -> String {
        let doc = try SwiftSoup.parse(html)
        try doc.select("script, style, nav, footer, aside, header").remove()

        guard let body = doc.body() else {
            return ""
        }

        let text = try body.text()

        return text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
