import Foundation

public protocol TranscriptionProvider: Sendable {
    func hasLocalModelAssets() async -> Bool
    func isModelReady() async -> Bool
    func preload() async throws
    func transcribe(
        fileURL: URL,
        languageCode: String?,
        onPartial: (@Sendable (String) -> Void)?
    ) async throws -> String
}

public extension TranscriptionProvider {
    func hasLocalModelAssets() async -> Bool { true }
    func isModelReady() async -> Bool { true }
    func preload() async throws {}
}

public enum TranscriptionError: LocalizedError, Sendable, Equatable {
    case missingAPIKey
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case unexpectedPayload(String)
    case modelNotLoaded
    case microphoneAccessDenied
    case recordingUnavailable

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing Mistral API key. Add it in Settings."
        case .invalidResponse:
            return "Invalid response from transcription service."
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .unexpectedPayload(let message):
            return "Unexpected response: \(message)"
        case .modelNotLoaded:
            return "Local model not loaded yet."
        case .microphoneAccessDenied:
            return "Microphone access is required. Enable it in Settings."
        case .recordingUnavailable:
            return "Recording did not produce an audio file."
        }
    }
}
