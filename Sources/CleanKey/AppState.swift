import AppKit
import CleanKeyCore
import Foundation
import os

final class AppState: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published private(set) var launchAtLoginEnabled = false
    @Published private(set) var permissionStatus: PermissionStatus = .missing
    @Published var lastError: String?

    let lockController: LockController

    private let settingsStore: SettingsStore
    private let permissionManager = PermissionManager()
    private let loginItemManager = LoginItemManager()
    private var permissionMonitorTimer: Timer?

    var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    var sourceURL: URL {
        let value = Bundle.main.object(forInfoDictionaryKey: "CleanKeySourceURL") as? String
        return URL(string: value ?? "https://github.com/loul/cleanKey")!
    }

    init(settingsStore: SettingsStore = SettingsStore()) {
        self.settingsStore = settingsStore
        let loadedSettings = settingsStore.load()
        settings = loadedSettings
        lockController = LockController(settings: loadedSettings)
    }

    func start() {
        refreshPermissions(prompt: false)
        refreshLaunchAtLogin()
        startPermissionMonitor()
    }

    func shutdown() {
        stopPermissionMonitor()
        lockController.unlock()
        lockController.stopEventTap()
    }

    func lockNow() {
        guard permissionManager.isTrusted() else {
            refreshPermissions(prompt: true)
            lastError = "Autorise CleanKey dans Accessibilité avant de verrouiller."
            return
        }

        if !lockController.isEventTapRunning {
            guard lockController.startEventTap() else {
                lastError = "CleanKey n'a pas pu créer l'intercepteur d'événements macOS."
                return
            }
        }

        lockController.lock()
    }

    func updateShortcut(_ shortcut: GlobalShortcut) {
        guard shortcut.isValidForGlobalUse else {
            lastError = "Choisis au moins Control, Option ou Command avec une touche non-modificatrice."
            return
        }

        settings.shortcut = shortcut
        saveSettings()
        lockController.updateSettings(settings)
        lastError = nil
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemManager.setEnabled(enabled)
            settings.launchAtLogin = enabled
            saveSettings()
            refreshLaunchAtLogin()
            lastError = nil
        } catch {
            refreshLaunchAtLogin()
            lastError = "Impossible de modifier le lancement au démarrage: \(error.localizedDescription)"
        }
    }

    func refreshPermissions(prompt: Bool) {
        let newStatus = permissionManager.status(prompt: prompt)
        let wasTrusted = permissionStatus == .trusted
        permissionStatus = newStatus

        if newStatus == .trusted && !lockController.isEventTapRunning {
            _ = lockController.startEventTap()
        } else if newStatus == .missing {
            if wasTrusted || lockController.isEventTapRunning || lockController.isLocked {
                AppLogger.lifecycle.warning("Accessibility permission missing while CleanKey is running; stopping event tap and unlocking.")
            }
            lockController.unlock()
            lockController.stopEventTap()
        }
    }

    func openAccessibilitySettings() {
        permissionManager.openAccessibilitySettings()
    }

    func openInputMonitoringSettings() {
        permissionManager.openInputMonitoringSettings()
    }

    private func refreshLaunchAtLogin() {
        launchAtLoginEnabled = loginItemManager.isEnabled()
        if settings.launchAtLogin != launchAtLoginEnabled {
            settings.launchAtLogin = launchAtLoginEnabled
            saveSettings()
        }
    }

    private func startPermissionMonitor() {
        stopPermissionMonitor()

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshPermissions(prompt: false)
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionMonitorTimer = timer
    }

    private func stopPermissionMonitor() {
        permissionMonitorTimer?.invalidate()
        permissionMonitorTimer = nil
    }

    private func saveSettings() {
        do {
            try settingsStore.save(settings)
        } catch {
            lastError = "Impossible d'enregistrer les réglages: \(error.localizedDescription)"
        }
    }
}
