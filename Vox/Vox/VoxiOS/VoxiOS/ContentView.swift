import SwiftUI
import VoxCore

struct ContentView: View {
    @EnvironmentObject private var controller: DictationSessionController

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.992, green: 0.725, blue: 0.537),
                    VoxiOSPalette.paper,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    statusCard
                    recordCard

                    if !controller.transcript.isEmpty {
                        transcriptCard
                    }

                    historyCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vox")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(VoxiOSPalette.ink)

            Text("Local dictation for iPhone. Record fast, get Parakeet transcription locally, copy, switch back, paste.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(VoxiOSPalette.muted)
        }
        .padding(.top, 8)
    }

    private var statusCard: some View {
        VoxCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    StatePill(text: controller.stateLabel, isActive: controller.state == .recording)
                    Spacer()
                    if controller.state == .recording {
                        Text(controller.elapsedTimeFormatted)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(VoxiOSPalette.ink)
                    }
                }

                if !controller.statusDetail.isEmpty {
                    Text(controller.statusDetail)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(controller.state == .failed ? Color.red : VoxiOSPalette.muted)
                } else if !controller.hasLocalModelAssets && !controller.isModelLoaded {
                    Text("First run downloads the local Parakeet model before transcription.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiOSPalette.muted)
                }
            }
        }
    }

    private var recordCard: some View {
        VoxCard {
            VStack(spacing: 20) {
                RecordOrbButton(
                    isRecording: controller.state == .recording,
                    isBusy: controller.state == .transcribing
                ) {
                    Task {
                        await controller.toggleRecording()
                    }
                }

                Text(primaryButtonTitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(VoxiOSPalette.ink)

                Text("Shortcut or Action Button can open Vox straight into recording. Finish speaking, stop, then paste where you need it.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(VoxiOSPalette.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var transcriptCard: some View {
        VoxCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Latest Transcript")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.8)
                    .foregroundStyle(VoxiOSPalette.muted)

                Text(controller.transcript)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(VoxiOSPalette.ink)
                    .textSelection(.enabled)

                HStack(spacing: 12) {
                    button("Copy", fill: VoxiOSPalette.ink, foreground: .white) {
                        controller.copyTranscript()
                    }

                    ShareLink(item: controller.transcript) {
                        Text("Share")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(VoxiOSPalette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.88))
                            )
                    }

                    button("Done", fill: Color.clear, foreground: VoxiOSPalette.ink) {
                        controller.clearTranscript()
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(VoxiOSPalette.line, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var historyCard: some View {
        VoxCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("History")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(1.8)
                        .foregroundStyle(VoxiOSPalette.muted)
                    Spacer()
                    if !controller.history.isEmpty {
                        Button("Clear All") {
                            controller.clearHistory()
                        }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(VoxiOSPalette.signal)
                    }
                }

                if controller.history.isEmpty {
                    Text("No saved transcripts yet.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(VoxiOSPalette.muted)
                } else {
                    VStack(spacing: 10) {
                        ForEach(controller.history) { item in
                            Button {
                                controller.copyHistoryItem(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(Self.timestampFormatter.string(from: item.createdAt).uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .tracking(1.2)
                                        .foregroundStyle(VoxiOSPalette.muted)

                                    Text(item.text)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(VoxiOSPalette.ink)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white.opacity(0.82))
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Copy Again") {
                                    controller.copyHistoryItem(item)
                                }
                                Button("Delete", role: .destructive) {
                                    controller.deleteHistoryItem(item)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func button(
        _ title: String,
        fill: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(fill)
                )
        }
        .buttonStyle(.plain)
    }

    private var primaryButtonTitle: String {
        switch controller.state {
        case .recording:
            return "TAP TO STOP AND TRANSCRIBE"
        case .transcribing:
            return "TRANSCRIBING"
        default:
            return "TAP TO START DICTATION"
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    ContentView()
        .environmentObject(DictationSessionController())
}
