import SwiftUI
import VoxCore

struct ContentView: View {
    @EnvironmentObject private var controller: RecordingController
    @AppStorage("vox.hotkey.keyCode") private var hotKeyCode: Int = HotKeyDefaults.keyCode
    @AppStorage("vox.hotkey.modifiers") private var hotKeyModifiers: Int = HotKeyDefaults.modifiers
    @AppStorage("vox.streaming") private var streamingEnabled: Bool = true

    var body: some View {
        ZStack {
            VoxColors.paper
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 32)
                    .padding(.top, 28)
                    .padding(.bottom, 16)

                HeavyDivider()
                    .padding(.horizontal, 32)

                ScrollView {
                    VStack(spacing: 0) {
                        statusSection
                        recordButtonSection
                        transcriptSection
                        historySection
                    }
                }

                footer
            }
        }
        .frame(minWidth: 480, minHeight: 680)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            VoxTypography.title("Vox")

            Spacer()

            Text("VOXTRAL AGENT V2.0")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(VoxColors.muted)

            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(VoxColors.black)
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SYSTEM STATE")
                .font(.system(size: 10, weight: .bold))
                .tracking(2.5)
                .foregroundColor(VoxColors.muted)

            HStack(alignment: .lastTextBaseline, spacing: 12) {
                if controller.isRecording {
                    Text("Recording")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(-0.5)
                        .foregroundColor(VoxColors.orange)

                    Text(controller.elapsedTimeFormatted)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(VoxColors.muted)
                } else if controller.isTranscribing {
                    Text("Transcribing")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(-0.5)
                        .foregroundColor(VoxColors.black)

                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Text("Ready")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(-0.5)
                        .foregroundColor(VoxColors.black)
                }
            }

            if let errorMessage = controller.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }

            if !AccessibilityPermission.isTrusted {
                Text("Enable Accessibility for auto-paste into other apps.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(VoxColors.muted)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Record Button Section

    private var recordButtonSection: some View {
        VStack(spacing: 20) {
            LightDivider()
                .padding(.horizontal, 32)

            SwissRecordButton(
                isRecording: controller.isRecording,
                isDisabled: controller.isTranscribing,
                action: { controller.toggleRecording() }
            )
            .padding(.vertical, 32)

            Text(controller.isRecording ? "RECORDING" : "START DICTATION")
                .font(.system(size: 11, weight: .bold))
                .tracking(3)
                .foregroundColor(controller.isRecording ? VoxColors.orange : VoxColors.black)

            Text("Press \(HotKeyFormatter.displayString(keyCode: hotKeyCode, modifiers: hotKeyModifiers)) to toggle")
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundColor(VoxColors.muted)

            LightDivider()
                .padding(.horizontal, 32)
                .padding(.top, 24)
        }
    }

    // MARK: - Transcript Section

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LIVE TRANSCRIPT")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundColor(VoxColors.muted)

                Spacer()

                SwissTextButton(title: "Copy") {
                    controller.copyTranscript()
                }

                SwissTextButton(title: "Clear") {
                    controller.transcript = ""
                }
                .padding(.leading, 16)
            }

            // Transcript display area
            VStack(alignment: .leading, spacing: 0) {
                if controller.transcript.isEmpty {
                    Text("Transcribed text will appear here...")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.5)
                        .foregroundColor(VoxColors.fadedText)
                } else {
                    HStack(alignment: .top, spacing: 0) {
                        Text(controller.transcript)
                            .font(.system(size: 28, weight: .bold))
                            .tracking(-0.5)
                            .foregroundColor(VoxColors.black)
                            .textSelection(.enabled)

                        if controller.isRecording || controller.isTranscribing {
                            OrangeCursor()
                                .padding(.leading, 2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeavyDivider()
                .padding(.horizontal, 32)

            HStack {
                Text("HISTORY LOG")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundColor(VoxColors.black)

                Spacer()

                if !controller.history.isEmpty {
                    SwissTextButton(title: "Clear All") {
                        controller.clearHistory()
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if controller.history.isEmpty {
                Text("No previous transcriptions yet.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(VoxColors.muted)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(controller.history) { item in
                        HistoryRowView(item: item, controller: controller)
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            HeavyDivider()

            HStack {
                Button(action: { controller.copyTranscript() }) {
                    Text("COPY")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundColor(VoxColors.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Rectangle()
                                .stroke(VoxColors.black, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)

                Button(action: { controller.pasteTranscript() }) {
                    Text("PASTE")
                        .font(.system(size: 10, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(VoxColors.black)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)

                Spacer()

                if !controller.lastActionMessage.isEmpty {
                    Text(controller.lastActionMessage.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(VoxColors.muted)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
        .background(VoxColors.paper)
    }
}

// MARK: - History Row

struct HistoryRowView: View {
    let item: TranscriptItem
    @ObservedObject var controller: RecordingController
    @State private var copyHovered = false
    @State private var trashHovered = false
    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Self.formatter.string(from: item.createdAt).uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(VoxColors.muted)

            HStack(alignment: .top, spacing: 12) {
                Text(item.text)
                    .font(.system(size: 17, weight: .bold))
                    .tracking(-0.3)
                    .foregroundColor(VoxColors.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    controller.copyHistoryItem(item)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(showCopied ? .green : (copyHovered ? .blue : VoxColors.muted))
                }
                .buttonStyle(.plain)
                .onHover { copyHovered = $0 }

                Button {
                    controller.deleteHistoryItem(item)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(trashHovered ? .red : VoxColors.muted)
                }
                .buttonStyle(.plain)
                .onHover { trashHovered = $0 }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            LightDivider()
                .padding(.horizontal, 32)
        }
        .contextMenu {
            Button("Copy") { controller.copyHistoryItem(item) }
            Button("Paste") { controller.pasteHistoryItem(item) }
            Divider()
            Button("Delete", role: .destructive) { controller.deleteHistoryItem(item) }
        }
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

#Preview {
    ContentView()
        .environmentObject(RecordingController())
}
