import Foundation
import Testing
@testable import VoxCore

private enum FakeFailure: Error, Sendable {
    case preload
    case transcribe
}

private struct FakeProvider: TranscriptionProvider {
    let hasAssets: Bool
    let ready: Bool
    let preloadFails: Bool
    let transcribedText: String
    let transcriptionFails: Bool

    func hasLocalModelAssets() async -> Bool {
        hasAssets
    }

    func isModelReady() async -> Bool {
        ready
    }

    func preload() async throws {
        if preloadFails {
            throw FakeFailure.preload
        }
    }

    func transcribe(
        fileURL: URL,
        languageCode: String?,
        onPartial: (@Sendable (String) -> Void)?
    ) async throws -> String {
        _ = fileURL
        _ = languageCode
        if transcriptionFails {
            throw FakeFailure.transcribe
        }
        onPartial?(transcribedText)
        return transcribedText
    }
}

private final class FakeRecorder: AudioRecording {
    var started = false
    var stopURL: URL?

    init(stopURL: URL? = URL(fileURLWithPath: "/tmp/test.wav")) {
        self.stopURL = stopURL
    }

    func start() throws {
        started = true
    }

    func stop() -> URL? {
        stopURL
    }
}

private final class FakeClipboard: ClipboardWriting {
    private(set) var copiedTexts: [String] = []

    func copy(_ text: String) {
        copiedTexts.append(text)
    }
}

private struct FakePermission: MicrophonePermissionRequesting {
    let granted: Bool

    func request() async -> Bool {
        granted
    }
}

@MainActor
private func makeController(
    provider: FakeProvider,
    recorder: FakeRecorder = FakeRecorder(),
    clipboard: FakeClipboard = FakeClipboard(),
    defaults: UserDefaults = UserDefaults(suiteName: "VoxCoreTests-\(UUID().uuidString)")!
) -> (DictationSessionController, FakeRecorder, FakeClipboard, TranscriptStore) {
    let store = TranscriptStore(defaults: defaults, storageKey: "history")
    let controller = DictationSessionController(
        transcriptionProvider: provider,
        audioRecorder: recorder,
        clipboard: clipboard,
        transcriptStore: store,
        microphonePermission: FakePermission(granted: true),
        launchModeStore: PendingLaunchModeStore(defaults: defaults, key: "launch")
    )
    return (controller, recorder, clipboard, store)
}

@Test @MainActor
func sessionTransitionsToCompletedAndCopiesTranscript() async throws {
    let provider = FakeProvider(
        hasAssets: true,
        ready: true,
        preloadFails: false,
        transcribedText: "hello world",
        transcriptionFails: false
    )
    let (controller, recorder, clipboard, store) = makeController(provider: provider)

    await controller.startRecording()
    #expect(recorder.started)
    #expect(controller.state == .recording)

    await controller.stopRecording()

    #expect(controller.state == .completed)
    #expect(controller.transcript == "hello world")
    #expect(clipboard.copiedTexts.last == "hello world")
    #expect(store.load().first?.text == "hello world")
}

@Test @MainActor
func deniedMicrophonePermissionMovesSessionToFailed() async {
    let defaults = UserDefaults(suiteName: "VoxCoreTests-\(UUID().uuidString)")!
    let recorder = FakeRecorder()
    let clipboard = FakeClipboard()
    let controller = DictationSessionController(
        transcriptionProvider: FakeProvider(
            hasAssets: true,
            ready: true,
            preloadFails: false,
            transcribedText: "",
            transcriptionFails: false
        ),
        audioRecorder: recorder,
        clipboard: clipboard,
        transcriptStore: TranscriptStore(defaults: defaults, storageKey: "history"),
        microphonePermission: FakePermission(granted: false),
        launchModeStore: PendingLaunchModeStore(defaults: defaults, key: "launch")
    )

    await controller.startRecording()

    #expect(controller.state == .failed)
    #expect(controller.errorMessage == TranscriptionError.microphoneAccessDenied.errorDescription)
}

@Test @MainActor
func transcriptStoreSuppressesImmediateDuplicates() {
    let defaults = UserDefaults(suiteName: "VoxCoreTests-\(UUID().uuidString)")!
    let store = TranscriptStore(defaults: defaults, storageKey: "history")

    _ = store.append("same text")
    let items = store.append("same text")

    #expect(items.count == 1)
    #expect(items.first?.text == "same text")
}

@Test @MainActor
func preloadReportsModelReadyAfterSuccess() async {
    let provider = FakeProvider(
        hasAssets: false,
        ready: false,
        preloadFails: false,
        transcribedText: "done",
        transcriptionFails: false
    )
    let (controller, _, _, _) = makeController(provider: provider)

    await controller.preloadModelIfNeeded()

    #expect(controller.isModelLoaded)
    #expect(controller.hasLocalModelAssets)
}
