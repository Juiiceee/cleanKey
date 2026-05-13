import CleanKeyCore
import Foundation

final class SettingsStore {
    private let defaults: UserDefaults
    private let settingsKey = "CleanKey.settings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: settingsKey) else {
            return AppSettings()
        }

        do {
            var settings = try JSONDecoder().decode(AppSettings.self, from: data)
            settings.enforceSafetyLimits()
            return settings
        } catch {
            return AppSettings()
        }
    }

    func save(_ settings: AppSettings) throws {
        var settings = settings
        settings.enforceSafetyLimits()
        let data = try JSONEncoder().encode(settings)
        defaults.set(data, forKey: settingsKey)
    }
}
