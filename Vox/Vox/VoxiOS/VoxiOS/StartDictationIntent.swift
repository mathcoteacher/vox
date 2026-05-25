import AppIntents
import VoxCore

struct StartDictationIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Dictation"
    static let description = IntentDescription("Open Vox and start recording immediately.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        PendingLaunchModeStore.shared.setPendingLaunchMode(.shortcutRecord)
        return .result()
    }
}

struct VoxShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartDictationIntent(),
            phrases: [
                "Start dictation in \(.applicationName)",
                "Record with \(.applicationName)",
            ],
            shortTitle: "Start Dictation",
            systemImageName: "waveform"
        )
    }
}
