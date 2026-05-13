import CoreGraphics

public struct GlobalShortcut: Codable, Equatable, Sendable {
    public var keyCode: UInt16
    public var modifiers: ShortcutModifiers

    public init(keyCode: UInt16, modifiers: ShortcutModifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public static let defaultShortcut = GlobalShortcut(
        keyCode: 37,
        modifiers: [.control, .option, .command]
    )

    public var displayString: String {
        modifiers.displayPrefix + KeyCodeNames.name(for: keyCode)
    }

    public var isValidForGlobalUse: Bool {
        modifiers.hasActivationModifier && !KeyCodeNames.isModifierKey(keyCode)
    }

    public func matches(keyCode: UInt16, flags: CGEventFlags) -> Bool {
        self.keyCode == keyCode && modifiers.matches(cgFlags: flags)
    }
}
