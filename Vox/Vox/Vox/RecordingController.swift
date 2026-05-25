import Foundation
import AVFoundation
import SwiftUI
import Combine
import AppKit
import VoxCore

@MainActor
final class RecordingController: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published var lastActionMessage = ""
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published var isModelLoaded = false
    @Published var isLoadingModel = false

    @AppStorage("vox.language") private var languageCode: String = ""
    @AppStorage("vox.streaming") private var streamingEnabled: Bool = true
    @AppStorage("vox.pasteIntoPreviousApp") private var pasteIntoPreviousApp: Bool = true
    @AppStorage("vox.provider") private var providerSetting: String = "cloud"

    private let audioRecorder = AudioRecorder()
    private let localProvider = ParakeetTranscriptionProvider()
    private var timer: Timer?
    private var recordingStart: Date?
    private var lastTargetAppPID: pid_t?
    @Published private(set) var history: [TranscriptItem] = []

    private var cloudProvider: MistralTranscriptionProvider {
        MistralTranscriptionProvider(streamingEnabled: streamingEnabled)
    }

    private var activeProvider: TranscriptionProvider {
        providerSetting == "local" ? localProvider : cloudProvider
    }

    var elapsedTimeFormatted: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init() {
        history = TranscriptHistoryStore.load()
        preloadLocalModelIfNeeded()
    }

    func preloadLocalModelIfNeeded() {
        guard providerSetting == "local", !localProvider.isLoaded, !isLoadingModel else { return }
        isLoadingModel = true
        Task.detached { [localProvider] in
            do {
                try await localProvider.loadModel()
                await MainActor.run {
                    self.isModelLoaded = true
                    self.isLoadingModel = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load local model: \(error.localizedDescription)"
                    self.isLoadingModel = false
                }
            }
        }
    }

    func toggleRecording(hotkeyTimestamp: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()) {
        guard !isTranscribing else {
            NSLog("Vox toggle: IGNORED (transcribing)")
            return
        }
        if isRecording {
            NSLog("Vox toggle: STOP recording")
            stopRecording()
        } else {
            NSLog("Vox toggle: START recording")
            startRecording(hotkeyTimestamp: hotkeyTimestamp)
        }
    }

    func startRecording(hotkeyTimestamp: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()) {
        captureTargetAppIfNeeded()
        errorMessage = nil
        lastActionMessage = ""

        Task {
            let granted = await MicrophonePermission.request()
            guard granted else {
                await MainActor.run {
                    errorMessage = "Microphone access is required. Enable it in System Settings."
                }
                return
            }

            do {
                try audioRecorder.start(hotkeyTimestamp: hotkeyTimestamp)
                recordingStart = Date()
                elapsedTime = 0
                isRecording = true
                startTimer()
            } catch {
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        stopTimer()

        guard let fileURL = audioRecorder.stop() else {
            errorMessage = "Recording did not produce an audio file."
            return
        }

        transcribe(fileURL: fileURL)
    }

    private func transcribe(fileURL: URL) {
        isTranscribing = true
        let provider = activeProvider
        let lang = languageCode.isEmpty ? nil : languageCode
        Task.detached {
            do {
                let text = try await provider.transcribe(
                    fileURL: fileURL,
                    languageCode: lang
                ) { partial in
                    Task { @MainActor in
                        self.transcript = partial
                    }
                }
                await MainActor.run {
                    self.transcript = text
                    if self.pasteIntoPreviousApp {
                        ClipboardPaster.copyAndPaste(text, targetAppPID: self.lastTargetAppPID)
                        self.lastActionMessage = "Transcript copied and pasted."
                    } else {
                        ClipboardPaster.copyToClipboard(text)
                        self.lastActionMessage = "Transcript copied."
                    }
                    self.addHistoryEntry(text)
                    self.isTranscribing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Transcription failed: \(error.localizedDescription)"
                    self.isTranscribing = false
                }
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            if let start = self.recordingStart {
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

    private func captureTargetAppIfNeeded() {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return }
        let voxBundleID = Bundle.main.bundleIdentifier
        if frontmost.bundleIdentifier != voxBundleID {
            lastTargetAppPID = frontmost.processIdentifier
        }
    }

    func copyTranscript() {
        ClipboardPaster.copyToClipboard(transcript)
    }

    func pasteTranscript() {
        ClipboardPaster.copyAndPaste(transcript, targetAppPID: lastTargetAppPID)
    }

    func copyHistoryItem(_ item: TranscriptItem) {
        ClipboardPaster.copyToClipboard(item.text)
    }

    func pasteHistoryItem(_ item: TranscriptItem) {
        ClipboardPaster.copyAndPaste(item.text, targetAppPID: lastTargetAppPID)
    }

    func deleteHistoryItem(_ item: TranscriptItem) {
        history.removeAll { $0.id == item.id }
        TranscriptHistoryStore.save(history)
    }

    func clearHistory() {
        history.removeAll()
        TranscriptHistoryStore.save(history)
    }

    private func addHistoryEntry(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let latest = history.first, latest.text == trimmed { return }
        let item = TranscriptItem(id: UUID(), text: trimmed, createdAt: Date())
        history.insert(item, at: 0)
        TranscriptHistoryStore.save(history)
    }
}

final class AudioRecorder {
    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var fileURL: URL?

    func start(hotkeyTimestamp: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()) throws {
        let engine = AVAudioEngine()
        let input = engine.inputNode

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("vox-\(UUID().uuidString).wav")

        // Pass nil format so the tap uses the hardware's actual sample rate.
        // The Parakeet local model can change the device to 24kHz, which causes
        // a mismatch if we hardcode the default 48kHz outputFormat.
        input.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            do {
                if self?.audioFile == nil {
                    self?.audioFile = try AVAudioFile(forWriting: url, settings: buffer.format.settings)
                    NSLog("Vox audio: recording at %g Hz", buffer.format.sampleRate)
                }
                try self?.audioFile?.write(from: buffer)
            } catch {
                NSLog("Audio write failed: \(error)")
            }
        }

        engine.prepare()
        try engine.start()

        let latencyMs = (CFAbsoluteTimeGetCurrent() - hotkeyTimestamp) * 1000
        NSLog("Vox hotkey→listening latency: %.1f ms", latencyMs)

        self.engine = engine
        self.audioFile = nil
        self.fileURL = url
    }

    func stop() -> URL? {
        guard let engine else { return nil }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        // Append 500ms of silence so the STT model can finalize its last decoding window.
        // Without this, audio that ends abruptly mid-word gets truncated by the model.
        if let file = audioFile {
            let format = file.processingFormat
            let frameCount = AVAudioFrameCount(format.sampleRate * 0.5)
            if let silence = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
                silence.frameLength = frameCount
                try? file.write(from: silence)
            }
        }

        let url = fileURL
        self.engine = nil
        self.audioFile = nil
        self.fileURL = nil
        return url
    }
}

enum MicrophonePermission {
    static func request() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
