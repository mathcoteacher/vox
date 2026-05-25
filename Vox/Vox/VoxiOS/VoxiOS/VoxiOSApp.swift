import SwiftUI
import VoxCore

@main
struct VoxiOSApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var controller = DictationSessionController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
                .task {
                    await controller.activatePendingLaunchModeIfNeeded()
                    if controller.state != .recording {
                        await controller.preloadModelIfNeeded()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await controller.activatePendingLaunchModeIfNeeded()
                        if controller.state == .idle && !controller.isModelLoaded && !controller.isPreparingModel {
                            await controller.preloadModelIfNeeded()
                        }
                    }
                }
        }
    }
}
