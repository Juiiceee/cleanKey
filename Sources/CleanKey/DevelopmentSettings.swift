import Foundation

enum DevelopmentSettings {
    static var skipsPermissionChecks: Bool {
        #if DEBUG
        return environmentFlag("CLEANKEY_SKIP_PERMISSIONS", defaultValue: true)
        #else
        return false
        #endif
    }

    private static func environmentFlag(_ name: String, defaultValue: Bool) -> Bool {
        guard let value = ProcessInfo.processInfo.environment[name]?.lowercased() else {
            return defaultValue
        }

        return ["1", "true", "yes", "on"].contains(value)
    }
}
