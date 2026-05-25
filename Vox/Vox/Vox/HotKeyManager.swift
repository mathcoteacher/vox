import Foundation
import Carbon
import CoreGraphics

final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var toggleAction: ((_ hotkeyTimestamp: CFAbsoluteTime) -> Void)?
    private var monitoredKeyCode: Int64 = 0
    private var lastToggleTime: CFAbsoluteTime = 0
    private static let debounceInterval: CFAbsoluteTime = 0.3  // 300ms debounce

    func registerToggleHotKey(keyCode: UInt32, modifiers: UInt32, action: @escaping (_ hotkeyTimestamp: CFAbsoluteTime) -> Void) {
        toggleAction = action

        // Clean up any existing registrations
        unregisterAll()

        // Check if this is a modifier-only key
        if HotKeyFormatter.isModifierKey(Int(keyCode)) {
            registerModifierKey(keyCode: keyCode, action: action)
        } else {
            registerTraditionalHotKey(keyCode: keyCode, modifiers: modifiers, action: action)
        }
    }

    private func registerTraditionalHotKey(keyCode: UInt32, modifiers: UInt32, action: @escaping (_ hotkeyTimestamp: CFAbsoluteTime) -> Void) {
        if eventHandler == nil {
            var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            let callback: EventHandlerUPP = { _, _, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.toggleAction?(CFAbsoluteTimeGetCurrent())
                return noErr
            }

            let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            InstallEventHandler(GetEventDispatcherTarget(), callback, 1, &eventSpec, selfPointer, &eventHandler)
        }

        var hotKeyID = EventHotKeyID(signature: fourCharCode("VOXT"), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
    }

    private func registerModifierKey(keyCode: UInt32, action: @escaping (_ hotkeyTimestamp: CFAbsoluteTime) -> Void) {
        monitoredKeyCode = Int64(keyCode)

        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(refcon).takeUnretainedValue()

            // Re-enable the tap if macOS disabled it (e.g. due to timeout)
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = manager.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }

            if type == .flagsChanged {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

                if keyCode == manager.monitoredKeyCode {
                    // Check if the key was just pressed (flag set) or released (flag cleared)
                    let flags = event.flags
                    let isPressed: Bool

                    switch Int(keyCode) {
                    case kVK_RightOption, kVK_Option:
                        isPressed = flags.contains(.maskAlternate)
                    case kVK_RightControl, kVK_Control:
                        isPressed = flags.contains(.maskControl)
                    case kVK_RightShift, kVK_Shift:
                        isPressed = flags.contains(.maskShift)
                    case kVK_RightCommand, kVK_Command:
                        isPressed = flags.contains(.maskCommand)
                    default:
                        isPressed = false
                    }

                    // Trigger on key release (when modifier is released), with debounce
                    if !isPressed {
                        let now = CFAbsoluteTimeGetCurrent()
                        let elapsed = now - manager.lastToggleTime
                        if elapsed > HotKeyManager.debounceInterval {
                            NSLog("Vox hotkey: toggle fired (%.0fms since last)", elapsed * 1000)
                            manager.lastToggleTime = now
                            DispatchQueue.main.async {
                                manager.toggleAction?(now)
                            }
                        } else {
                            NSLog("Vox hotkey: DEBOUNCED (%.0fms since last)", elapsed * 1000)
                        }
                    } else {
                        NSLog("Vox hotkey: modifier key pressed (waiting for release)")
                    }
                }
            }

            return Unmanaged.passUnretained(event)
        }

        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: selfPointer
        ) else {
            NSLog("Failed to create event tap - Accessibility permission may be required")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    private func unregisterAll() {
        // Unregister traditional hotkey
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        // Remove event tap
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }
    }
}

private func fourCharCode(_ string: String) -> FourCharCode {
    var result: FourCharCode = 0
    for byte in string.utf8 {
        result = (result << 8) + FourCharCode(byte)
    }
    return result
}
