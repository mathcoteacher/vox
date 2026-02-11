import AppKit

enum AppWindowManager {
    static func applyMenuBarMode(_ enabled: Bool) {
        DispatchQueue.main.async {
            if enabled {
                NSApp.setActivationPolicy(.accessory)
                NSApp.windows
                    .filter { $0.level != .statusBar }
                    .forEach { $0.orderOut(nil) }
            } else {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.forEach { $0.makeKeyAndOrderFront(nil) }
            }
        }
    }

    static func showMainWindow() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.forEach { $0.makeKeyAndOrderFront(nil) }
        }
    }
}
