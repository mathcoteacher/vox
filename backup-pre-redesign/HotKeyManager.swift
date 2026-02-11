import Foundation
import Carbon

final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var toggleAction: (() -> Void)?

    func registerToggleHotKey(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        toggleAction = action

        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if eventHandler == nil {
            var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            let callback: EventHandlerUPP = { _, _, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.toggleAction?()
                return noErr
            }

            let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            InstallEventHandler(GetEventDispatcherTarget(), callback, 1, &eventSpec, selfPointer, &eventHandler)
        }

        var hotKeyID = EventHotKeyID(signature: fourCharCode("VOXT"), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
    }
}

private func fourCharCode(_ string: String) -> FourCharCode {
    var result: FourCharCode = 0
    for byte in string.utf8 {
        result = (result << 8) + FourCharCode(byte)
    }
    return result
}
