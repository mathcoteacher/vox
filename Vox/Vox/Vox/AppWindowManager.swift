import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    /// Dock icon clicked. Set regular mode and let the system create a window if needed.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.setActivationPolicy(.regular)
        }
        return true
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window.level == .normal else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let hasVisibleMainWindows = NSApp.windows.contains { w in
                w.isVisible && w.level == .normal
            }
            if !hasVisibleMainWindows {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}

enum AppWindowManager {
    /// Try to find and show an existing main window (not Settings).
    /// Returns true if a window was found.
    @discardableResult
    static func showExistingMainWindow() -> Bool {
        let mainWindow = NSApp.windows.first { w in
            w.level == .normal
                && !w.title.localizedCaseInsensitiveContains("settings")
        }
        guard let mainWindow else { return false }

        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            mainWindow.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
