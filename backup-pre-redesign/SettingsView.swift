import SwiftUI
import Carbon

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var statusMessage: String = ""

    @AppStorage("vox.language") private var languageCode: String = ""
    @AppStorage("vox.streaming") private var streamingEnabled: Bool = true
    @AppStorage("vox.menuBarOnly") private var menuBarOnly: Bool = false
    @AppStorage("vox.pasteIntoPreviousApp") private var pasteIntoPreviousApp: Bool = true
    @AppStorage("vox.hotkey.keyCode") private var hotKeyCode: Int = HotKeyDefaults.keyCode
    @AppStorage("vox.hotkey.modifiers") private var hotKeyModifiers: Int = HotKeyDefaults.modifiers

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.system(size: 20, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Mistral API Key")
                    .font(.system(size: 13, weight: .semibold))
                SecureField("Paste your key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Language (optional)")
                    .font(.system(size: 13, weight: .semibold))
                TextField("e.g. en, fr, es", text: $languageCode)
                    .textFieldStyle(.roundedBorder)
                Text("Leave blank for auto-detect.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Streaming transcription")
                    .font(.system(size: 13, weight: .semibold))
                Toggle("Show results as they stream back", isOn: $streamingEnabled)
                Text("If disabled, Vox will wait for the full transcript before updating.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Auto paste")
                    .font(.system(size: 13, weight: .semibold))
                Toggle("Paste into the app you were using", isOn: $pasteIntoPreviousApp)
                Text("If disabled, Vox only copies to the clipboard.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Menu bar mode")
                    .font(.system(size: 13, weight: .semibold))
                Toggle("Menu bar only (hide dock icon)", isOn: $menuBarOnly)
                Text("You can still open the main window from the menu bar.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Hotkey")
                    .font(.system(size: 13, weight: .semibold))
                Picker("Key", selection: $hotKeyCode) {
                    ForEach(HotKeyCatalog.allKeys) { key in
                        Text(key.title).tag(key.keyCode)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Toggle("Command", isOn: modifierBinding(Int(cmdKey)))
                    Toggle("Option", isOn: modifierBinding(Int(optionKey)))
                    Toggle("Control", isOn: modifierBinding(Int(controlKey)))
                    Toggle("Shift", isOn: modifierBinding(Int(shiftKey)))
                }
                .font(.system(size: 12))

                Text("Avoid hotkeys used by macOS (e.g., Command + Space).")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            HStack {
                Button("Close") {
                    dismiss()
                }

                Spacer()

                Button("Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 520)
        .onAppear {
            if let key = try? KeychainHelper.shared.readAPIKey() {
                apiKey = key
            }
        }
    }

    private func save() {
        do {
            try KeychainHelper.shared.saveAPIKey(apiKey)
            statusMessage = "API key saved."
        } catch {
            statusMessage = "Failed to save API key: \(error.localizedDescription)"
        }
    }

    private func modifierBinding(_ modifier: Int) -> Binding<Bool> {
        Binding(
            get: { (hotKeyModifiers & modifier) != 0 },
            set: { newValue in
                if newValue {
                    hotKeyModifiers |= modifier
                } else {
                    hotKeyModifiers &= ~modifier
                }
            }
        )
    }
}

#Preview {
    SettingsView()
}
