import FluidAudio
import Foundation

extension AsrManager: @retroactive @unchecked Sendable {}

public actor ParakeetTranscriptionProvider: TranscriptionProvider {
    private let version: AsrModelVersion
    private var asrManager: AsrManager?
    private var loadTask: Task<Void, Error>?

    public init(version: AsrModelVersion = .v2) {
        self.version = version
    }

    public func hasLocalModelAssets() async -> Bool {
        let cacheDirectory = AsrModels.defaultCacheDirectory(for: version)
        return AsrModels.modelsExist(at: cacheDirectory, version: version)
    }

    public func isModelReady() async -> Bool {
        asrManager != nil
    }

    public func preload() async throws {
        try await ensureLoaded()
    }

    public func transcribe(
        fileURL: URL,
        languageCode: String?,
        onPartial: (@Sendable (String) -> Void)?
    ) async throws -> String {
        _ = languageCode
        try await ensureLoaded()

        guard let asrManager else {
            throw TranscriptionError.modelNotLoaded
        }

        let result = try await asrManager.transcribe(fileURL)
        onPartial?(result.text)
        return result.text
    }

    private func ensureLoaded() async throws {
        if asrManager != nil {
            return
        }

        if let loadTask {
            try await loadTask.value
            return
        }

        let version = self.version
        let task = Task<Void, Error> {
            let models = try await AsrModels.downloadAndLoad(version: version)
            let manager = AsrManager(config: .default)
            try await manager.initialize(models: models)
            await self.finishLoading(with: manager)
        }

        loadTask = task

        do {
            try await task.value
        } catch {
            loadTask = nil
            throw error
        }
    }

    private func finishLoading(with manager: AsrManager) {
        asrManager = manager
        loadTask = nil
    }
}
