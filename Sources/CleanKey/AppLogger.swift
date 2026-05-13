import Foundation
import os

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "dev.loul.CleanKey"

    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    static let lock = Logger(subsystem: subsystem, category: "lock")
    static let overlay = Logger(subsystem: subsystem, category: "overlay")
    static let eventTap = Logger(subsystem: subsystem, category: "eventTap")
}
