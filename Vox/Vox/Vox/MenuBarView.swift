import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var controller: RecordingController
    @Environment(\.openWindow) private var openWindow
    @AppStorage("vox.streaming") private var streamingEnabled: Bool = true
    @AppStorage("vox.provider") private var providerSetting: String = "cloud"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .lastTextBaseline) {
                Text("VOX")
                    .font(.system(size: 16, weight: .black))
                    .tracking(-0.5)
                    .foregroundColor(VoxColors.black)

                Spacer()

                Text(statusText.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(controller.isRecording ? VoxColors.orange : VoxColors.muted)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            HeavyDivider()
                .padding(.horizontal, 16)

            // Record button row
            Button(action: { controller.toggleRecording() }) {
                HStack {
                    // Mini record indicator
                    ZStack {
                        Circle()
                            .stroke(controller.isRecording ? VoxColors.orange : VoxColors.black, lineWidth: 1)
                            .frame(width: 20, height: 20)
                        Circle()
                            .fill(controller.isRecording ? VoxColors.orange : VoxColors.black)
                            .frame(width: 8, height: 8)
                    }

                    Text(controller.isRecording ? "STOP RECORDING" : "START RECORDING")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(VoxColors.black)

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .disabled(controller.isTranscribing)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            LightDivider()
                .padding(.horizontal, 16)

            // Toggles
            VStack(alignment: .leading, spacing: 0) {
                if providerSetting == "cloud" {
                    menuToggle("Streaming", isOn: $streamingEnabled)
                }
            }

            LightDivider()
                .padding(.horizontal, 16)

            // Actions
            VStack(alignment: .leading, spacing: 0) {
                menuButton("Open Vox") {
                    if !AppWindowManager.showExistingMainWindow() {
                        NSApp.setActivationPolicy(.regular)
                        openWindow(id: "main")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }
                }

                SettingsLink {
                    HStack {
                        Text("SETTINGS")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(VoxColors.black)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            HeavyDivider()
                .padding(.horizontal, 16)

            // Quit
            menuButton("Quit Vox") {
                NSApp.terminate(nil)
            }
            .padding(.bottom, 8)
        }
        .background(VoxColors.paper)
        .frame(width: 220)
    }

    private var statusText: String {
        if controller.isRecording { return "Recording" }
        if controller.isTranscribing { return "Transcribing" }
        return "Ready"
    }

    private func menuToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(VoxColors.black)
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func menuButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(VoxColors.black)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(RecordingController())
}
