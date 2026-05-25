import SwiftUI
import Carbon
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject private var controller: RecordingController
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var statusMessage: String = ""
    @State private var selectedSection: SettingsSection = .general

    @AppStorage("vox.language") private var languageCode: String = ""
    @AppStorage("vox.streaming") private var streamingEnabled: Bool = true
    @AppStorage("vox.pasteIntoPreviousApp") private var pasteIntoPreviousApp: Bool = true
    @AppStorage("vox.hotkey.keyCode") private var hotKeyCode: Int = HotKeyDefaults.keyCode
    @AppStorage("vox.hotkey.modifiers") private var hotKeyModifiers: Int = HotKeyDefaults.modifiers
    @AppStorage("vox.provider") private var providerSetting: String = "cloud"

    enum SettingsSection: String, CaseIterable {
        case general = "General"
        case hotkeys = "Hotkeys"
        case mistralAPI = "Mistral API"
        case transcription = "Transcription"
        case about = "About"

        var icon: String {
            switch self {
            case .general: return "gear"
            case .hotkeys: return "keyboard"
            case .mistralAPI: return "key.horizontal"
            case .transcription: return "text.alignleft"
            case .about: return "info.circle"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            sidebar

            // Divider
            Rectangle()
                .fill(VoxColors.divider)
                .frame(width: 1)

            // Content
            contentArea
        }
        .background(VoxColors.paper)
        .frame(width: 600, height: 480)
        .onAppear {
            if let key = try? KeychainHelper.shared.readAPIKey() {
                apiKey = key
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SettingsSection.allCases, id: \.self) { section in
                sidebarButton(section)
            }

            Spacer()
        }
        .frame(width: 180)
        .padding(.top, 20)
    }

    private func sidebarButton(_ section: SettingsSection) -> some View {
        Button(action: { selectedSection = section }) {
            HStack(spacing: 12) {
                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedSection == section ? VoxColors.black : VoxColors.muted)
                    .frame(width: 20)

                Text(section.rawValue)
                    .font(.system(size: 13, weight: selectedSection == section ? .bold : .medium))
                    .foregroundColor(selectedSection == section ? VoxColors.black : VoxColors.muted)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(selectedSection == section ? VoxColors.divider : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content Area

    private var contentArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch selectedSection {
                case .general:
                    generalContent
                case .hotkeys:
                    hotkeysContent
                case .mistralAPI:
                    mistralAPIContent
                case .transcription:
                    transcriptionContent
                case .about:
                    aboutContent
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - General Section

    private var launchAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private var generalContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionHeader("General")

            settingsToggle(
                title: "Launch at login",
                description: "Start Vox automatically when you log in",
                isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Failed to update launch at login: \(error)")
                        }
                    }
                )
            )
        }
    }

    // MARK: - Hotkeys Section

    private var isModifierOnlyKey: Bool {
        HotKeyCatalog.modifierKeys.contains { $0.keyCode == hotKeyCode }
    }

    private var hotkeysContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionHeader("Global Trigger")

            // Large hotkey display
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        if isModifierOnlyKey {
                            // Simple display for modifier-only keys
                            Text(keyDisplayString)
                                .font(.system(size: 48, weight: .black))
                                .tracking(-2)
                                .foregroundColor(VoxColors.black)
                        } else {
                            // Traditional modifier + key display
                            Text(modifierDisplayString)
                                .font(.system(size: 48, weight: .black))
                                .tracking(-2)
                                .foregroundColor(VoxColors.black)

                            Text("+")
                                .font(.system(size: 36, weight: .black))
                                .foregroundColor(VoxColors.black)

                            Text(keyDisplayString)
                                .font(.system(size: 48, weight: .black))
                                .tracking(-2)
                                .foregroundColor(VoxColors.black)
                        }
                    }

                    Spacer()
                }
                .padding(24)
                .overlay(
                    Rectangle()
                        .stroke(VoxColors.black, lineWidth: 2)
                )

                Text("PRESS TO TOGGLE RECORDING")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(VoxColors.muted)
                    .padding(.top, 8)
            }

            LightDivider()

            // Key picker
            VStack(alignment: .leading, spacing: 12) {
                Text("DICTATION KEY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundColor(VoxColors.muted)

                Picker("", selection: $hotKeyCode) {
                    ForEach(HotKeyCatalog.allKeys) { key in
                        Text(key.title).tag(key.keyCode)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            // Modifier toggles - only show for non-modifier keys
            if !isModifierOnlyKey {
                VStack(alignment: .leading, spacing: 12) {
                    Text("MODIFIERS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.5)
                        .foregroundColor(VoxColors.muted)

                    HStack(spacing: 16) {
                        modifierToggle("Command", modifier: Int(cmdKey))
                        modifierToggle("Option", modifier: Int(optionKey))
                        modifierToggle("Control", modifier: Int(controlKey))
                        modifierToggle("Shift", modifier: Int(shiftKey))
                    }
                }
            }

            Text(isModifierOnlyKey
                ? "Press the key once to start, press again to stop and transcribe."
                : "Avoid hotkeys used by macOS (e.g., Command + Space).")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(VoxColors.muted)
        }
    }

    private var modifierDisplayString: String {
        var parts: [String] = []
        if (hotKeyModifiers & Int(cmdKey)) != 0 { parts.append("CMD") }
        if (hotKeyModifiers & Int(optionKey)) != 0 { parts.append("OPT") }
        if (hotKeyModifiers & Int(controlKey)) != 0 { parts.append("CTRL") }
        if (hotKeyModifiers & Int(shiftKey)) != 0 { parts.append("SHIFT") }
        return parts.isEmpty ? "OPTION" : parts.joined(separator: "+")
    }

    private var keyDisplayString: String {
        HotKeyCatalog.allKeys.first { $0.keyCode == hotKeyCode }?.title.uppercased() ?? "SPACE"
    }

    private func modifierToggle(_ title: String, modifier: Int) -> some View {
        Toggle(isOn: modifierBinding(modifier)) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(VoxColors.black)
        }
        .toggleStyle(.checkbox)
    }

    // MARK: - Mistral API Section

    private var mistralAPIContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionHeader("Mistral Engine")

            if providerSetting == "local" {
                Text("API key is only needed for Cloud (Mistral) transcription.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(VoxColors.muted)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("API KEY")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.5)
                    .foregroundColor(VoxColors.muted)

                SecureField("Paste your key", text: $apiKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .padding(12)
                    .background(
                        Rectangle()
                            .stroke(VoxColors.divider, lineWidth: 1)
                    )

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(VoxColors.muted)
                }
            }

            Button(action: save) {
                Text("SAVE KEY")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(VoxColors.black)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Transcription Section

    private var transcriptionContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionHeader("Transcription")

            VStack(alignment: .leading, spacing: 20) {
                // Provider picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("PROVIDER")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.5)
                        .foregroundColor(VoxColors.muted)

                    Picker("", selection: $providerSetting) {
                        Text("Cloud (Mistral)").tag("cloud")
                        Text("Local (Parakeet)").tag("local")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: providerSetting) { _ in
                        controller.preloadLocalModelIfNeeded()
                    }
                }

                // Model status (only when local is selected)
                if providerSetting == "local" {
                    HStack(spacing: 8) {
                        if controller.isLoadingModel {
                            ProgressView()
                                .controlSize(.small)
                            Text("Downloading model...")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(VoxColors.muted)
                        } else if controller.isModelLoaded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                            Text("Model ready")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(VoxColors.muted)
                        }
                    }
                }

                LightDivider()

                if providerSetting == "cloud" {
                    settingsToggle(
                        title: "Streaming transcription",
                        description: "Show results as they stream back",
                        isOn: $streamingEnabled
                    )

                    LightDivider()
                }

                settingsToggle(
                    title: "Auto paste",
                    description: "Paste into the app you were using",
                    isOn: $pasteIntoPreviousApp
                )

                LightDivider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("LANGUAGE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.5)
                        .foregroundColor(VoxColors.muted)

                    TextField("e.g. en, fr, es (blank for auto-detect)", text: $languageCode)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .padding(12)
                        .background(
                            Rectangle()
                                .stroke(VoxColors.divider, lineWidth: 1)
                        )

                    if providerSetting == "local" {
                        Text("Local (Parakeet) supports English only. Language setting is used in Cloud mode.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(VoxColors.muted)
                    }
                }
            }
        }
    }

    private func settingsToggle(title: String, description: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(VoxColors.black)

                Text(description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(VoxColors.muted)
            }
        }
        .toggleStyle(.switch)
    }

    // MARK: - About Section

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionHeader("About")

            VStack(alignment: .leading, spacing: 8) {
                Text("VOX")
                    .font(.system(size: 48, weight: .black))
                    .tracking(-2)
                    .foregroundColor(VoxColors.black)

                Text("VOXTRAL AGENT V2.0")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(VoxColors.muted)
            }

            LightDivider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Push-to-transcribe voice capture powered by Mistral's Voxtral API.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(VoxColors.black)

                Text("Hold your hotkey to record, release to transcribe and paste.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(VoxColors.muted)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(2.5)
                .foregroundColor(VoxColors.muted)

            HeavyDivider()
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
        .environmentObject(RecordingController())
}
