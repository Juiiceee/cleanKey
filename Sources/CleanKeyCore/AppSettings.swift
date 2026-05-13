import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let maximumAutoUnlockDuration: TimeInterval = 180
    public static let minimumAutoUnlockDuration: TimeInterval = 10

    public var shortcut: GlobalShortcut
    public var launchAtLogin: Bool
    public var unlockHoldDuration: TimeInterval
    public var autoUnlockDuration: TimeInterval

    public init(
        shortcut: GlobalShortcut = .defaultShortcut,
        launchAtLogin: Bool = false,
        unlockHoldDuration: TimeInterval = 5,
        autoUnlockDuration: TimeInterval = AppSettings.maximumAutoUnlockDuration
    ) {
        self.shortcut = shortcut
        self.launchAtLogin = launchAtLogin
        self.unlockHoldDuration = unlockHoldDuration
        self.autoUnlockDuration = Self.clampedAutoUnlockDuration(autoUnlockDuration)
    }

    public mutating func enforceSafetyLimits() {
        autoUnlockDuration = Self.clampedAutoUnlockDuration(autoUnlockDuration)
    }

    private static func clampedAutoUnlockDuration(_ duration: TimeInterval) -> TimeInterval {
        min(max(duration, minimumAutoUnlockDuration), maximumAutoUnlockDuration)
    }
}
