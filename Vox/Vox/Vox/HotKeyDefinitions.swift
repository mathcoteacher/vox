import Carbon

struct HotKeyDefaults {
    static let keyCode = Int(kVK_RightOption)
    static let modifiers = 0  // No modifiers - just the key itself
}

struct HotKeyChoice: Identifiable, Hashable {
    let id: Int
    let title: String
    let keyCode: Int
    let isModifierKey: Bool

    init(id: Int, title: String, keyCode: Int, isModifierKey: Bool = false) {
        self.id = id
        self.title = title
        self.keyCode = keyCode
        self.isModifierKey = isModifierKey
    }
}

enum HotKeyCatalog {
    // Modifier keys that can be used alone
    static let modifierKeys: [HotKeyChoice] = [
        HotKeyChoice(id: Int(kVK_RightOption), title: "Right Option", keyCode: Int(kVK_RightOption), isModifierKey: true),
        HotKeyChoice(id: Int(kVK_Option), title: "Left Option", keyCode: Int(kVK_Option), isModifierKey: true),
        HotKeyChoice(id: Int(kVK_RightControl), title: "Right Control", keyCode: Int(kVK_RightControl), isModifierKey: true),
        HotKeyChoice(id: Int(kVK_Control), title: "Left Control", keyCode: Int(kVK_Control), isModifierKey: true),
    ]

    static let allKeys: [HotKeyChoice] = modifierKeys + [
        HotKeyChoice(id: Int(kVK_Space), title: "Space", keyCode: Int(kVK_Space)),
        HotKeyChoice(id: Int(kVK_Return), title: "Return", keyCode: Int(kVK_Return)),
        HotKeyChoice(id: Int(kVK_Tab), title: "Tab", keyCode: Int(kVK_Tab)),
        HotKeyChoice(id: Int(kVK_Escape), title: "Escape", keyCode: Int(kVK_Escape)),
        HotKeyChoice(id: Int(kVK_Delete), title: "Delete", keyCode: Int(kVK_Delete)),
        HotKeyChoice(id: Int(kVK_ForwardDelete), title: "Forward Delete", keyCode: Int(kVK_ForwardDelete))
    ] + letters + numbers + functionKeys

    private static let letters: [HotKeyChoice] = [
        HotKeyChoice(id: Int(kVK_ANSI_A), title: "A", keyCode: Int(kVK_ANSI_A)),
        HotKeyChoice(id: Int(kVK_ANSI_B), title: "B", keyCode: Int(kVK_ANSI_B)),
        HotKeyChoice(id: Int(kVK_ANSI_C), title: "C", keyCode: Int(kVK_ANSI_C)),
        HotKeyChoice(id: Int(kVK_ANSI_D), title: "D", keyCode: Int(kVK_ANSI_D)),
        HotKeyChoice(id: Int(kVK_ANSI_E), title: "E", keyCode: Int(kVK_ANSI_E)),
        HotKeyChoice(id: Int(kVK_ANSI_F), title: "F", keyCode: Int(kVK_ANSI_F)),
        HotKeyChoice(id: Int(kVK_ANSI_G), title: "G", keyCode: Int(kVK_ANSI_G)),
        HotKeyChoice(id: Int(kVK_ANSI_H), title: "H", keyCode: Int(kVK_ANSI_H)),
        HotKeyChoice(id: Int(kVK_ANSI_I), title: "I", keyCode: Int(kVK_ANSI_I)),
        HotKeyChoice(id: Int(kVK_ANSI_J), title: "J", keyCode: Int(kVK_ANSI_J)),
        HotKeyChoice(id: Int(kVK_ANSI_K), title: "K", keyCode: Int(kVK_ANSI_K)),
        HotKeyChoice(id: Int(kVK_ANSI_L), title: "L", keyCode: Int(kVK_ANSI_L)),
        HotKeyChoice(id: Int(kVK_ANSI_M), title: "M", keyCode: Int(kVK_ANSI_M)),
        HotKeyChoice(id: Int(kVK_ANSI_N), title: "N", keyCode: Int(kVK_ANSI_N)),
        HotKeyChoice(id: Int(kVK_ANSI_O), title: "O", keyCode: Int(kVK_ANSI_O)),
        HotKeyChoice(id: Int(kVK_ANSI_P), title: "P", keyCode: Int(kVK_ANSI_P)),
        HotKeyChoice(id: Int(kVK_ANSI_Q), title: "Q", keyCode: Int(kVK_ANSI_Q)),
        HotKeyChoice(id: Int(kVK_ANSI_R), title: "R", keyCode: Int(kVK_ANSI_R)),
        HotKeyChoice(id: Int(kVK_ANSI_S), title: "S", keyCode: Int(kVK_ANSI_S)),
        HotKeyChoice(id: Int(kVK_ANSI_T), title: "T", keyCode: Int(kVK_ANSI_T)),
        HotKeyChoice(id: Int(kVK_ANSI_U), title: "U", keyCode: Int(kVK_ANSI_U)),
        HotKeyChoice(id: Int(kVK_ANSI_V), title: "V", keyCode: Int(kVK_ANSI_V)),
        HotKeyChoice(id: Int(kVK_ANSI_W), title: "W", keyCode: Int(kVK_ANSI_W)),
        HotKeyChoice(id: Int(kVK_ANSI_X), title: "X", keyCode: Int(kVK_ANSI_X)),
        HotKeyChoice(id: Int(kVK_ANSI_Y), title: "Y", keyCode: Int(kVK_ANSI_Y)),
        HotKeyChoice(id: Int(kVK_ANSI_Z), title: "Z", keyCode: Int(kVK_ANSI_Z))
    ]

    private static let numbers: [HotKeyChoice] = [
        HotKeyChoice(id: Int(kVK_ANSI_0), title: "0", keyCode: Int(kVK_ANSI_0)),
        HotKeyChoice(id: Int(kVK_ANSI_1), title: "1", keyCode: Int(kVK_ANSI_1)),
        HotKeyChoice(id: Int(kVK_ANSI_2), title: "2", keyCode: Int(kVK_ANSI_2)),
        HotKeyChoice(id: Int(kVK_ANSI_3), title: "3", keyCode: Int(kVK_ANSI_3)),
        HotKeyChoice(id: Int(kVK_ANSI_4), title: "4", keyCode: Int(kVK_ANSI_4)),
        HotKeyChoice(id: Int(kVK_ANSI_5), title: "5", keyCode: Int(kVK_ANSI_5)),
        HotKeyChoice(id: Int(kVK_ANSI_6), title: "6", keyCode: Int(kVK_ANSI_6)),
        HotKeyChoice(id: Int(kVK_ANSI_7), title: "7", keyCode: Int(kVK_ANSI_7)),
        HotKeyChoice(id: Int(kVK_ANSI_8), title: "8", keyCode: Int(kVK_ANSI_8)),
        HotKeyChoice(id: Int(kVK_ANSI_9), title: "9", keyCode: Int(kVK_ANSI_9))
    ]

    private static let functionKeys: [HotKeyChoice] = [
        HotKeyChoice(id: Int(kVK_F1), title: "F1", keyCode: Int(kVK_F1)),
        HotKeyChoice(id: Int(kVK_F2), title: "F2", keyCode: Int(kVK_F2)),
        HotKeyChoice(id: Int(kVK_F3), title: "F3", keyCode: Int(kVK_F3)),
        HotKeyChoice(id: Int(kVK_F4), title: "F4", keyCode: Int(kVK_F4)),
        HotKeyChoice(id: Int(kVK_F5), title: "F5", keyCode: Int(kVK_F5)),
        HotKeyChoice(id: Int(kVK_F6), title: "F6", keyCode: Int(kVK_F6)),
        HotKeyChoice(id: Int(kVK_F7), title: "F7", keyCode: Int(kVK_F7)),
        HotKeyChoice(id: Int(kVK_F8), title: "F8", keyCode: Int(kVK_F8)),
        HotKeyChoice(id: Int(kVK_F9), title: "F9", keyCode: Int(kVK_F9)),
        HotKeyChoice(id: Int(kVK_F10), title: "F10", keyCode: Int(kVK_F10)),
        HotKeyChoice(id: Int(kVK_F11), title: "F11", keyCode: Int(kVK_F11)),
        HotKeyChoice(id: Int(kVK_F12), title: "F12", keyCode: Int(kVK_F12))
    ]
}

enum HotKeyFormatter {
    static func displayString(keyCode: Int, modifiers: Int) -> String {
        // Check if it's a modifier-only key
        if let choice = HotKeyCatalog.allKeys.first(where: { $0.keyCode == keyCode }), choice.isModifierKey {
            return choice.title
        }

        var parts: [String] = []
        if modifiers & Int(cmdKey) != 0 { parts.append("Command") }
        if modifiers & Int(optionKey) != 0 { parts.append("Option") }
        if modifiers & Int(controlKey) != 0 { parts.append("Control") }
        if modifiers & Int(shiftKey) != 0 { parts.append("Shift") }

        let keyTitle = HotKeyCatalog.allKeys.first(where: { $0.keyCode == keyCode })?.title ?? "Key \(keyCode)"
        parts.append(keyTitle)
        return parts.joined(separator: " + ")
    }

    static func isModifierKey(_ keyCode: Int) -> Bool {
        HotKeyCatalog.modifierKeys.contains { $0.keyCode == keyCode }
    }
}
