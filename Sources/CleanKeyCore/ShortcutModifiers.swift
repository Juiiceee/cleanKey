import AppKit
import CoreGraphics

public struct ShortcutModifiers: OptionSet, Codable, Equatable, Sendable {
    public let rawValue: Int

    public static let control = ShortcutModifiers(rawValue: 1 << 0)
    public static let option = ShortcutModifiers(rawValue: 1 << 1)
    public static let command = ShortcutModifiers(rawValue: 1 << 2)
    public static let shift = ShortcutModifiers(rawValue: 1 << 3)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(eventFlags: NSEvent.ModifierFlags) {
        var modifiers: ShortcutModifiers = []
        if eventFlags.contains(.control) {
            modifiers.insert(.control)
        }
        if eventFlags.contains(.option) {
            modifiers.insert(.option)
        }
        if eventFlags.contains(.command) {
            modifiers.insert(.command)
        }
        if eventFlags.contains(.shift) {
            modifiers.insert(.shift)
        }
        self = modifiers
    }

    public init(cgFlags: CGEventFlags) {
        var modifiers: ShortcutModifiers = []
        if cgFlags.contains(.maskControl) {
            modifiers.insert(.control)
        }
        if cgFlags.contains(.maskAlternate) {
            modifiers.insert(.option)
        }
        if cgFlags.contains(.maskCommand) {
            modifiers.insert(.command)
        }
        if cgFlags.contains(.maskShift) {
            modifiers.insert(.shift)
        }
        self = modifiers
    }

    public var eventFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if contains(.control) {
            flags.insert(.control)
        }
        if contains(.option) {
            flags.insert(.option)
        }
        if contains(.command) {
            flags.insert(.command)
        }
        if contains(.shift) {
            flags.insert(.shift)
        }
        return flags
    }

    public var displayPrefix: String {
        var parts: [String] = []
        if contains(.control) {
            parts.append("⌃")
        }
        if contains(.option) {
            parts.append("⌥")
        }
        if contains(.command) {
            parts.append("⌘")
        }
        if contains(.shift) {
            parts.append("⇧")
        }
        return parts.joined()
    }

    public var hasActivationModifier: Bool {
        contains(.control) || contains(.option) || contains(.command)
    }

    public func containsAll(_ required: ShortcutModifiers) -> Bool {
        intersection(required) == required
    }

    public func matches(cgFlags: CGEventFlags) -> Bool {
        self == ShortcutModifiers(cgFlags: cgFlags)
    }
}
