import Foundation
import VoxCore

final class ParakeetTranscriptionProvider: TranscriptionProvider, @unchecked Sendable {
    private let provider = VoxCore.ParakeetTranscriptionProvider()
    private let stateQueue = DispatchQueue(label: "vox.parakeet.provider")
    private var loaded = false

    var isLoaded: Bool {
        stateQueue.sync { loaded }
    }

    func loadModel() async throws {
        try await provider.preload()
        stateQueue.sync {
            loaded = true
        }
    }

    func hasLocalModelAssets() async -> Bool {
        await provider.hasLocalModelAssets()
    }

    func isModelReady() async -> Bool {
        if isLoaded {
            return true
        }

        let ready = await provider.isModelReady()
        if ready {
            stateQueue.sync {
                loaded = true
            }
        }
        return ready
    }

    func preload() async throws {
        try await loadModel()
    }

    func transcribe(
        fileURL: URL,
        languageCode: String?,
        onPartial: (@Sendable (String) -> Void)?
    ) async throws -> String {
        let text = try await provider.transcribe(
            fileURL: fileURL,
            languageCode: languageCode,
            onPartial: onPartial
        )

        stateQueue.sync {
            loaded = true
        }

        return text
    }
}
