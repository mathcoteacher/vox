import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var controller: RecordingController
    @AppStorage("vox.hotkey.keyCode") private var hotKeyCode: Int = HotKeyDefaults.keyCode
    @AppStorage("vox.hotkey.modifiers") private var hotKeyModifiers: Int = HotKeyDefaults.modifiers
    @AppStorage("vox.streaming") private var streamingEnabled: Bool = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.12), Color(red: 0.18, green: 0.20, blue: 0.26)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                mainCard
                transcriptCard
                historyCard
                footer
            }
            .padding(28)
        }
        .frame(minWidth: 760, minHeight: 640)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Vox")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)

                Text("Push-to-transcribe with Voxtral")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
            }

            Spacer()

            SettingsLink {
                Text("Settings")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var mainCard: some View {
        HStack(spacing: 24) {
            recordButton
            VStack(alignment: .leading, spacing: 12) {
                statusLine
                hotkeyLine
                streamingLine
                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.red.opacity(0.9))
                }
                if !AccessibilityPermission.isTrusted {
                    Text("Enable Accessibility for auto-paste into other apps.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.75))
                }
            }
            Spacer()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var recordButton: some View {
        Button(action: {
            controller.toggleRecording()
        }) {
            ZStack {
                Circle()
                    .fill(controller.isRecording ? Color.red.opacity(0.9) : Color.white.opacity(0.9))
                    .frame(width: 92, height: 92)
                    .shadow(color: controller.isRecording ? Color.red.opacity(0.5) : Color.black.opacity(0.3), radius: 12, x: 0, y: 6)

                Image(systemName: controller.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(controller.isRecording ? .white : Color.black.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
        .disabled(controller.isTranscribing)
    }

    private var statusLine: some View {
        HStack(spacing: 10) {
            if controller.isRecording {
                Text("Recording")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            } else if controller.isTranscribing {
                ProgressView()
                    .progressViewStyle(.circular)
                Text("Transcribing")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            } else {
                Text("Ready")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            if controller.isRecording {
                Text(controller.elapsedTimeFormatted)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
            }
        }
    }

    private var hotkeyLine: some View {
        Text("Hotkey: \(HotKeyFormatter.displayString(keyCode: hotKeyCode, modifiers: hotKeyModifiers))")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color.white.opacity(0.65))
    }

    private var streamingLine: some View {
        Text(streamingEnabled ? "Streaming transcription enabled" : "Streaming transcription off")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.white.opacity(0.65))
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            TextEditor(text: $controller.transcript)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color.black.opacity(0.4))
                .cornerRadius(12)
                .frame(maxHeight: 260)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button("Clear") {
                    controller.clearHistory()
                }
                .buttonStyle(.bordered)
                .disabled(controller.history.isEmpty)
            }

            if controller.history.isEmpty {
                Text("No previous transcriptions yet.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(controller.history) { item in
                            historyRow(item)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 220)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func historyRow(_ item: TranscriptItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Self.historyFormatter.string(from: item.createdAt))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))

                Spacer()

                Button {
                    controller.copyHistoryItem(item)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy")

                Button {
                    controller.pasteHistoryItem(item)
                } label: {
                    Image(systemName: "arrow.down.doc")
                }
                .buttonStyle(.borderless)
                .help("Paste")

                Button {
                    controller.deleteHistoryItem(item)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete")
            }

            Text(item.text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.black.opacity(0.25))
        .cornerRadius(10)
    }

    private var footer: some View {
        HStack {
            Button("Copy") {
                controller.copyTranscript()
            }
            .buttonStyle(.bordered)

            Button("Paste") {
                controller.pasteTranscript()
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            Text(controller.lastActionMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.white.opacity(0.6))
        }
    }
}

extension ContentView {
    private static let historyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    ContentView()
        .environmentObject(RecordingController())
}
