import SwiftUI

@main
struct VoxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller: RecordingController
    @AppStorage("vox.hotkey.keyCode") private var hotKeyCode: Int = HotKeyDefaults.keyCode
    @AppStorage("vox.hotkey.modifiers") private var hotKeyModifiers: Int = HotKeyDefaults.modifiers

    init() {
        let controller = RecordingController()
        _controller = StateObject(wrappedValue: controller)
        registerHotKey(for: controller)
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(controller)
                .onAppear {
                    AccessibilityPermission.requestIfNeeded()
                }
                .onChange(of: hotKeyCode) { _ in
                    registerHotKey(for: controller)
                }
                .onChange(of: hotKeyModifiers) { _ in
                    registerHotKey(for: controller)
                }
        }
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra("Vox", systemImage: "waveform") {
            MenuBarView()
                .environmentObject(controller)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(controller)
        }
    }

    private func registerHotKey(for controller: RecordingController) {
        HotKeyManager.shared.registerToggleHotKey(
            keyCode: UInt32(hotKeyCode),
            modifiers: UInt32(hotKeyModifiers)
        ) { hotkeyTimestamp in
            controller.toggleRecording(hotkeyTimestamp: hotkeyTimestamp)
        }
    }
}
