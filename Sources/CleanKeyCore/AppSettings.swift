import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let maximumAutoUnlockDuration: TimeInterval = 180
    public static let minimumAutoUnlockDuration: TimeInterval = 10
    public static let unlockHoldDurationOptions: [TimeInterval] = [2, 3, 5]
    public static let defaultUnlockHoldDuration: TimeInterval = 2
    public static let minimumUnlockHoldDuration: TimeInterval = 1
    public static let maximumUnlockHoldDuration: TimeInterval = 10

    public var shortcut: GlobalShortcut
    public var launchAtLogin: Bool
    public var unlockHoldDuration: TimeInterval
    public var autoUnlockDuration: TimeInterval

    public init(
        shortcut: GlobalShortcut = .defaultShortcut,
        launchAtLogin: Bool = false,
        unlockHoldDuration: TimeInterval = AppSettings.defaultUnlockHoldDuration,
        autoUnlockDuration: TimeInterval = AppSettings.maximumAutoUnlockDuration
    ) {
        self.shortcut = shortcut
        self.launchAtLogin = launchAtLogin
        self.unlockHoldDuration = Self.clampedUnlockHoldDuration(unlockHoldDuration)
        self.autoUnlockDuration = Self.clampedAutoUnlockDuration(autoUnlockDuration)
    }

    public mutating func enforceSafetyLimits() {
        unlockHoldDuration = Self.clampedUnlockHoldDuration(unlockHoldDuration)
        autoUnlockDuration = Self.clampedAutoUnlockDuration(autoUnlockDuration)
    }

    private static func clampedUnlockHoldDuration(_ duration: TimeInterval) -> TimeInterval {
        min(max(duration, minimumUnlockHoldDuration), maximumUnlockHoldDuration)
    }

    private static func clampedAutoUnlockDuration(_ duration: TimeInterval) -> TimeInterval {
        min(max(duration, minimumAutoUnlockDuration), maximumAutoUnlockDuration)
    }
}
