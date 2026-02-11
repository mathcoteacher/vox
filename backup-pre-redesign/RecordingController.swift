import Foundation
import AVFoundation
import SwiftUI
import Combine
import AppKit

@MainActor
final class RecordingController: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published var lastActionMessage = ""
    @Published private(set) var elapsedTime: TimeInterval = 0

    @AppStorage("vox.language") private var languageCode: String = ""
    @AppStorage("vox.streaming") private var streamingEnabled: Bool = true
    @AppStorage("vox.pasteIntoPreviousApp") private var pasteIntoPreviousApp: Bool = true

    private let audioRecorder = AudioRecorder()
    private let transcriber = TranscriptionService()
    private var timer: Timer?
    private var recordingStart: Date?
    private var lastTargetAppPID: pid_t?
    @Published private(set) var history: [TranscriptItem] = []

    var elapsedTimeFormatted: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init() {
        history = TranscriptHistoryStore.load()
    }

    func toggleRecording() {
        guard !isTranscribing else { return }
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
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
                try audioRecorder.start()
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
        Task {
            do {
                let text = try await transcriber.transcribe(
                    fileURL: fileURL,
                    languageCode: self.languageCode.isEmpty ? nil : self.languageCode,
                    stream: self.streamingEnabled
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

    func start() throws {
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("vox-\(UUID().uuidString).wav")
        let file = try AVAudioFile(forWriting: url, settings: format.settings)

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            do {
                try file.write(from: buffer)
            } catch {
                NSLog("Audio write failed: \(error)")
            }
        }

        engine.prepare()
        try engine.start()

        self.engine = engine
        self.audioFile = file
        self.fileURL = url
    }

    func stop() -> URL? {
        guard let engine else { return nil }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

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
