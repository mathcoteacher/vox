import AVFoundation
import Foundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public enum LaunchMode: String, Codable, Sendable {
    case normal
    case shortcutRecord
}

public final class PendingLaunchModeStore: @unchecked Sendable {
    public static let shared = PendingLaunchModeStore()

    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "vox.pendingLaunchMode") {
        self.defaults = defaults
        self.key = key
    }

    public func setPendingLaunchMode(_ mode: LaunchMode) {
        defaults.set(mode.rawValue, forKey: key)
    }

    public func consumePendingLaunchMode() -> LaunchMode {
        guard let rawValue = defaults.string(forKey: key),
              let mode = LaunchMode(rawValue: rawValue)
        else {
            return .normal
        }

        defaults.removeObject(forKey: key)
        return mode
    }
}

protocol AudioRecording: AnyObject {
    func start() throws
    func stop() -> URL?
}

protocol ClipboardWriting {
    func copy(_ text: String)
}

protocol MicrophonePermissionRequesting: Sendable {
    func request() async -> Bool
}

struct PlatformClipboard: ClipboardWriting {
    func copy(_ text: String) {
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #elseif canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
}

struct SystemMicrophonePermission: MicrophonePermissionRequesting {
    func request() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

final class AudioRecorder: AudioRecording {
    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var fileURL: URL?

    func start() throws {
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("vox-\(UUID().uuidString).wav")

        input.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            do {
                if self?.audioFile == nil {
                    self?.audioFile = try AVAudioFile(forWriting: url, settings: buffer.format.settings)
                }
                try self?.audioFile?.write(from: buffer)
            } catch {
                NSLog("Audio write failed: \(error.localizedDescription)")
            }
        }

        engine.prepare()
        try engine.start()

        self.engine = engine
        self.audioFile = nil
        self.fileURL = url
    }

    func stop() -> URL? {
        guard let engine else {
            return nil
        }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

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
