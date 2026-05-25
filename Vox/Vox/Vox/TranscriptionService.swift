import Foundation
import VoxCore

struct MistralTranscriptionProvider: TranscriptionProvider {
    var streamingEnabled: Bool = true

    func transcribe(
        fileURL: URL,
        languageCode: String?,
        onPartial: (@Sendable (String) -> Void)?
    ) async throws -> String {
        if streamingEnabled {
            return try await transcribeStreaming(fileURL: fileURL, languageCode: languageCode, onPartial: onPartial)
        }
        return try await transcribeOnce(fileURL: fileURL, languageCode: languageCode)
    }

    private let endpoint = URL(string: "https://api.mistral.ai/v1/audio/transcriptions")!
    private let model = "voxtral-mini-latest"

    private func transcribeOnce(fileURL: URL, languageCode: String?) async throws -> String {
        let apiKey = try KeychainHelper.shared.readAPIKey()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        var form = MultipartFormDataBuilder()
        form.addField(name: "model", value: model)
        if let languageCode, !languageCode.isEmpty {
            form.addField(name: "language", value: languageCode)
        }
        try form.addFile(name: "file", fileURL: fileURL, mimeType: "audio/wav")

        request.setValue("multipart/form-data; boundary=\(form.boundary)", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.upload(for: request, from: form.build())

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranscriptionError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        if let transcription = try? JSONDecoder().decode(TranscriptionResponse.self, from: data) {
            return transcription.text
        }

        let message = String(data: data, encoding: .utf8) ?? "Unexpected response"
        throw TranscriptionError.unexpectedPayload(message)
    }

    private func transcribeStreaming(
        fileURL: URL,
        languageCode: String?,
        onPartial: (@Sendable (String) -> Void)?
    ) async throws -> String {
        let apiKey = try KeychainHelper.shared.readAPIKey()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        var form = MultipartFormDataBuilder()
        form.addField(name: "model", value: model)
        form.addField(name: "stream", value: "true")
        if let languageCode, !languageCode.isEmpty {
            form.addField(name: "language", value: languageCode)
        }
        try form.addFile(name: "file", fileURL: fileURL, mimeType: "audio/wav")

        request.setValue("multipart/form-data; boundary=\(form.boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = form.build()

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            var errorData = Data()
            for try await byte in bytes {
                errorData.append(byte)
            }
            let message = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw TranscriptionError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        var fullText = ""
        for try await line in bytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("data:") else { continue }
            let payload = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" {
                break
            }

            guard let data = payload.data(using: .utf8) else { continue }
            if let event = try? JSONDecoder().decode(TranscriptionStreamEnvelope.self, from: data) {
                if applyStreamEvent(event, fullText: &fullText) {
                    onPartial?(fullText)
                }
            }
        }

        if !fullText.isEmpty {
            return fullText
        }

        return try await transcribeOnce(fileURL: fileURL, languageCode: languageCode)
    }

    private func applyStreamEvent(_ event: TranscriptionStreamEnvelope, fullText: inout String) -> Bool {
        if let text = event.text {
            fullText = text
            return true
        }
        if let text = event.delta?.text {
            fullText += text
            return true
        }
        if let text = event.segment?.text {
            fullText += text
            return true
        }
        if let data = event.data {
            if let text = data.text {
                fullText = text
                return true
            }
            if let text = data.delta?.text {
                fullText += text
                return true
            }
            if let text = data.segment?.text {
                fullText += text
                return true
            }
        }
        return false
    }
}

struct TranscriptionResponse: Decodable {
    let text: String
}

struct TranscriptionStreamEnvelope: Decodable {
    struct Delta: Decodable { let text: String? }
    struct Segment: Decodable { let text: String? }
    struct DataPayload: Decodable {
        let text: String?
        let delta: Delta?
        let segment: Segment?
    }

    let text: String?
    let delta: Delta?
    let segment: Segment?
    let data: DataPayload?
}

struct MultipartFormDataBuilder {
    let boundary: String
    private var data = Data()

    init() {
        boundary = "Boundary-\(UUID().uuidString)"
    }

    mutating func addField(name: String, value: String) {
        data.append("--\(boundary)\r\n")
        data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        data.append("\(value)\r\n")
    }

    mutating func addFile(name: String, fileURL: URL, mimeType: String) throws {
        let filename = fileURL.lastPathComponent
        let fileData = try Data(contentsOf: fileURL)
        data.append("--\(boundary)\r\n")
        data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        data.append("Content-Type: \(mimeType)\r\n\r\n")
        data.append(fileData)
        data.append("\r\n")
    }

    func build() -> Data {
        var finalData = data
        finalData.append("--\(boundary)--\r\n")
        return finalData
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
