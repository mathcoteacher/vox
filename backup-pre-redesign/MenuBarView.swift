import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var controller: RecordingController
    @AppStorage("vox.menuBarOnly") private var menuBarOnly: Bool = false
    @AppStorage("vox.streaming") private var streamingEnabled: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vox")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(controller.isRecording ? "Recording" : (controller.isTranscribing ? "Transcribing" : "Ready"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Button(controller.isRecording ? "Stop Recording" : "Start Recording") {
                controller.toggleRecording()
            }
            .disabled(controller.isTranscribing)

            Toggle("Streaming", isOn: $streamingEnabled)
                .toggleStyle(.switch)

            Toggle("Menu Bar Only", isOn: $menuBarOnly)
                .toggleStyle(.switch)

            HStack {
                Button("Open Vox") {
                    AppWindowManager.showMainWindow()
                }
                SettingsLink {
                    Text("Settings")
                }
            }

            Divider()

            Button("Quit Vox") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 240)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(RecordingController())
}
