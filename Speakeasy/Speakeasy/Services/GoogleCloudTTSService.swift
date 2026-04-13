import Foundation

actor GoogleCloudTTSService {
    private let session: URLSession
    private let maxChunkSize = 4900 // Google TTS limit is 5000 bytes of input

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Synthesis

    /// Synthesizes text to MP3 audio data, chunking if needed
    func synthesize(
        text: String,
        voiceName: String,
        languageCode: String,
        speakingRate: Float,
        apiKey: String
    ) async throws -> Data {
        guard !apiKey.isEmpty else {
            throw GoogleTTSError.missingAPIKey
        }

        let chunks = splitText(text)
        var audioData = Data()

        for chunk in chunks {
            let chunkData = try await synthesizeChunk(
                text: chunk,
                voiceName: voiceName,
                languageCode: languageCode,
                speakingRate: speakingRate,
                apiKey: apiKey
            )
            audioData.append(chunkData)
        }

        return audioData
    }

    private func synthesizeChunk(
        text: String,
        voiceName: String,
        languageCode: String,
        speakingRate: Float,
        apiKey: String
    ) async throws -> Data {
        let url = URL(string: "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(apiKey)")!

        let body: [String: Any] = [
            "input": ["text": text],
            "voice": [
                "languageCode": languageCode,
                "name": voiceName
            ],
            "audioConfig": [
                "audioEncoding": "MP3",
                "speakingRate": speakingRate
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleTTSError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleTTSError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let audioContent = json["audioContent"] as? String,
              let audioData = Data(base64Encoded: audioContent) else {
            throw GoogleTTSError.invalidAudioData
        }

        return audioData
    }

    // MARK: - Voice Discovery

    /// Fetches available voices from Google Cloud TTS API
    func listVoices(apiKey: String, languageCode: String? = nil) async throws -> [Voice] {
        guard !apiKey.isEmpty else {
            throw GoogleTTSError.missingAPIKey
        }

        var urlString = "https://texttospeech.googleapis.com/v1/voices?key=\(apiKey)"
        if let lang = languageCode {
            urlString += "&languageCode=\(lang)"
        }

        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleTTSError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleTTSError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let voicesArray = json["voices"] as? [[String: Any]] else {
            return []
        }

        return voicesArray.compactMap { voiceDict -> Voice? in
            guard let name = voiceDict["name"] as? String,
                  let languageCodes = voiceDict["languageCodes"] as? [String],
                  let gender = voiceDict["ssmlGender"] as? String,
                  let firstLang = languageCodes.first else {
                return nil
            }
            return Voice(googleName: name, languageCode: firstLang, gender: gender)
        }
        .sorted { $0.name < $1.name }
    }

    // MARK: - Text Chunking

    /// Splits text into chunks at sentence boundaries, respecting the API limit
    private func splitText(_ text: String) -> [String] {
        guard text.count > maxChunkSize else {
            return [text]
        }

        var chunks: [String] = []
        var remaining = text

        while !remaining.isEmpty {
            if remaining.count <= maxChunkSize {
                chunks.append(remaining)
                break
            }

            // Find a good break point (sentence boundary) within the limit
            let searchRange = remaining.prefix(maxChunkSize)
            let breakPoint: String.Index

            if let lastPeriod = searchRange.lastIndex(where: { $0 == "." || $0 == "!" || $0 == "?" }) {
                breakPoint = remaining.index(after: lastPeriod)
            } else if let lastNewline = searchRange.lastIndex(of: "\n") {
                breakPoint = remaining.index(after: lastNewline)
            } else if let lastSpace = searchRange.lastIndex(of: " ") {
                breakPoint = remaining.index(after: lastSpace)
            } else {
                breakPoint = remaining.index(remaining.startIndex, offsetBy: maxChunkSize)
            }

            let chunk = String(remaining[remaining.startIndex..<breakPoint]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !chunk.isEmpty {
                chunks.append(chunk)
            }
            remaining = String(remaining[breakPoint...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return chunks
    }
}

// MARK: - Errors

enum GoogleTTSError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case invalidAudioData

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Google Cloud API key is not configured. Add it in Settings."
        case .invalidResponse:
            return "Invalid response from Google Cloud TTS"
        case .apiError(let statusCode, let message):
            if statusCode == 403 {
                return "API key is invalid or TTS API is not enabled"
            }
            return "Google Cloud TTS error (\(statusCode)): \(message)"
        case .invalidAudioData:
            return "Failed to decode audio from Google Cloud TTS"
        }
    }
}
