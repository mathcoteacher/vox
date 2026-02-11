import SwiftUI

@main
struct VoxApp: App {
    @StateObject private var controller: RecordingController
    @AppStorage("vox.hotkey.keyCode") private var hotKeyCode: Int = HotKeyDefaults.keyCode
    @AppStorage("vox.hotkey.modifiers") private var hotKeyModifiers: Int = HotKeyDefaults.modifiers
    @AppStorage("vox.menuBarOnly") private var menuBarOnly: Bool = false

    init() {
        let controller = RecordingController()
        _controller = StateObject(wrappedValue: controller)
        registerHotKey(for: controller)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
                .onAppear {
                    AccessibilityPermission.requestIfNeeded()
                    AppWindowManager.applyMenuBarMode(menuBarOnly)
                }
                .onChange(of: menuBarOnly) { newValue in
                    AppWindowManager.applyMenuBarMode(newValue)
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
        }
    }

    private func registerHotKey(for controller: RecordingController) {
        HotKeyManager.shared.registerToggleHotKey(
            keyCode: UInt32(hotKeyCode),
            modifiers: UInt32(hotKeyModifiers)
        ) {
            controller.toggleRecording()
        }
    }
}
