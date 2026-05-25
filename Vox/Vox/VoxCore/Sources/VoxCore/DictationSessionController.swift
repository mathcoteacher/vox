import Combine
import Foundation

public enum DictationSessionState: Equatable, Sendable {
    case idle
    case recording
    case transcribing
    case completed
    case failed
}

@MainActor
public final class DictationSessionController: ObservableObject {
    @Published public private(set) var state: DictationSessionState = .idle
    @Published public private(set) var transcript: String = ""
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var completionMessage: String = ""
    @Published public private(set) var elapsedTime: TimeInterval = 0
    @Published public private(set) var isPreparingModel: Bool = false
    @Published public private(set) var isModelLoaded: Bool = false
    @Published public private(set) var hasLocalModelAssets: Bool = false
    @Published public private(set) var history: [TranscriptItem]
    @Published public private(set) var currentLaunchMode: LaunchMode = .normal

    private let transcriptionProvider: any TranscriptionProvider
    private let audioRecorder: any AudioRecording
    private let clipboard: any ClipboardWriting
    private let transcriptStore: TranscriptStore
    private let microphonePermission: any MicrophonePermissionRequesting
    private let launchModeStore: PendingLaunchModeStore
    private var timer: Timer?
    private var recordingStart: Date?

    public convenience init() {
        self.init(
            transcriptionProvider: ParakeetTranscriptionProvider(),
            audioRecorder: AudioRecorder(),
            clipboard: PlatformClipboard(),
            transcriptStore: TranscriptStore(),
            microphonePermission: SystemMicrophonePermission(),
            launchModeStore: .shared
        )
    }

    init(
        transcriptionProvider: any TranscriptionProvider,
        audioRecorder: any AudioRecording,
        clipboard: any ClipboardWriting,
        transcriptStore: TranscriptStore,
        microphonePermission: any MicrophonePermissionRequesting,
        launchModeStore: PendingLaunchModeStore
    ) {
        self.transcriptionProvider = transcriptionProvider
        self.audioRecorder = audioRecorder
        self.clipboard = clipboard
        self.transcriptStore = transcriptStore
        self.microphonePermission = microphonePermission
        self.launchModeStore = launchModeStore
        self.history = transcriptStore.load()
    }

    public var elapsedTimeFormatted: String {
        let totalSeconds = Int(elapsedTime)
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    public var stateLabel: String {
        switch state {
        case .idle:
            return errorMessage == nil ? "Ready" : "Error"
        case .recording:
            return "Recording"
        case .transcribing:
            return "Transcribing"
        case .completed:
            return "Copied"
        case .failed:
            return "Error"
        }
    }

    public var statusDetail: String {
        if let errorMessage {
            return errorMessage
        }
        if isPreparingModel {
            return completionMessage
        }
        return completionMessage
    }

    public func preloadModelIfNeeded() async {
        hasLocalModelAssets = await transcriptionProvider.hasLocalModelAssets()

        if await transcriptionProvider.isModelReady() {
            isModelLoaded = true
            hasLocalModelAssets = true
            if completionMessage.isEmpty {
                completionMessage = "Local model ready."
            }
            return
        }

        guard !isPreparingModel else {
            return
        }

        isPreparingModel = true
        errorMessage = nil
        completionMessage = hasLocalModelAssets ? "Loading local model..." : "Downloading local model..."

        do {
            try await transcriptionProvider.preload()
            isModelLoaded = true
            hasLocalModelAssets = true
            if state == .idle {
                completionMessage = "Local model ready."
            }
        } catch {
            state = .failed
            errorMessage = "Failed to prepare local model: \(error.localizedDescription)"
        }

        isPreparingModel = false
    }

    public func activatePendingLaunchModeIfNeeded() async {
        currentLaunchMode = launchModeStore.consumePendingLaunchMode()
        guard currentLaunchMode == .shortcutRecord else {
            return
        }

        currentLaunchMode = .normal

        guard state != .recording, state != .transcribing else {
            return
        }

        await startRecording()
    }

    public func toggleRecording() async {
        if state == .recording {
            await stopRecording()
        } else if state != .transcribing {
            await startRecording()
        }
    }

    public func startRecording() async {
        guard state != .recording, state != .transcribing else {
            return
        }

        errorMessage = nil
        completionMessage = ""
        transcript = ""

        let granted = await microphonePermission.request()
        guard granted else {
            state = .failed
            errorMessage = TranscriptionError.microphoneAccessDenied.errorDescription
            return
        }

        do {
            try audioRecorder.start()
            recordingStart = Date()
            elapsedTime = 0
            state = .recording
            startTimer()
        } catch {
            state = .failed
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    public func stopRecording() async {
        guard state == .recording else {
            return
        }

        stopTimer()
        state = .transcribing

        guard let fileURL = audioRecorder.stop() else {
            state = .failed
            errorMessage = TranscriptionError.recordingUnavailable.errorDescription
            return
        }

        do {
            if !(await transcriptionProvider.isModelReady()) {
                hasLocalModelAssets = await transcriptionProvider.hasLocalModelAssets()
                isPreparingModel = true
                completionMessage = hasLocalModelAssets ? "Loading local model..." : "Downloading local model..."
                try await transcriptionProvider.preload()
                isPreparingModel = false
                isModelLoaded = true
                hasLocalModelAssets = true
            }

            let text = try await transcriptionProvider.transcribe(
                fileURL: fileURL,
                languageCode: nil,
                onPartial: nil
            )

            transcript = text
            clipboard.copy(text)
            history = transcriptStore.append(text)
            completionMessage = "Copied to clipboard."
            errorMessage = nil
            state = .completed
        } catch {
            isPreparingModel = false
            state = .failed
            errorMessage = "Transcription failed: \(error.localizedDescription)"
        }
    }

    public func copyTranscript() {
        guard !transcript.isEmpty else {
            return
        }
        clipboard.copy(transcript)
        completionMessage = "Copied to clipboard."
    }

    public func clearTranscript() {
        transcript = ""
        if state == .completed {
            state = .idle
        }
        if errorMessage == nil {
            completionMessage = ""
        }
    }

    public func copyHistoryItem(_ item: TranscriptItem) {
        clipboard.copy(item.text)
        completionMessage = "Copied to clipboard."
    }

    public func deleteHistoryItem(_ item: TranscriptItem) {
        history = transcriptStore.remove(id: item.id)
    }

    public func clearHistory() {
        transcriptStore.clear()
        history = []
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.recordingStart else {
                    return
                }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil

        if let start = recordingStart {
            elapsedTime = Date().timeIntervalSince(start)
        }

        recordingStart = nil
    }
}
