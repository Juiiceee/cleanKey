import AppKit
import Combine

final class StatusBarController: NSObject {
    private let appState: AppState
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private lazy var settingsWindowController = SettingsWindowController(appState: appState)
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        super.init()
        configureStatusItem()
        rebuildMenu()
        observeState()
    }

    private func configureStatusItem() {
        updateStatusItemAppearance()
    }

    private func observeState() {
        appState.lockController.$isLocked
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        appState.lockController.$isUnlockHoldActive
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
            }
            .store(in: &cancellables)

        appState.lockController.$isReleaseGuardActive
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
            }
            .store(in: &cancellables)

        appState.$permissionStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)

        appState.$launchAtLoginEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)
    }

    private func updateStatusItemAppearance() {
        guard let button = statusItem.button else {
            return
        }

        let lockController = appState.lockController
        let symbolName: String
        let description: String

        if lockController.isReleaseGuardActive {
            symbolName = "hourglass"
            description = "CleanKey relâchement sécurisé"
        } else if lockController.isUnlockHoldActive {
            symbolName = "stopwatch.fill"
            description = "CleanKey déverrouillage en cours"
        } else if lockController.isLocked {
            symbolName = "lock.fill"
            description = "CleanKey verrouillé"
        } else {
            symbolName = "keyboard"
            description = "CleanKey prêt"
        }

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
        image?.isTemplate = true
        button.image = image
        button.toolTip = description
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let title = appState.lockController.isLocked ? "CleanKey verrouillé" : "CleanKey prêt"
        let status = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)

        let shortcut = NSMenuItem(title: "Raccourci: \(appState.settings.shortcut.displayString)", action: nil, keyEquivalent: "")
        shortcut.isEnabled = false
        menu.addItem(shortcut)

        menu.addItem(.separator())

        let lockItem = NSMenuItem(title: "Verrouiller maintenant", action: #selector(lockNow), keyEquivalent: "")
        lockItem.target = self
        lockItem.isEnabled = !appState.lockController.isLocked
        menu.addItem(lockItem)

        let settingsItem = NSMenuItem(title: "Réglages...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let permissionsItem = NSMenuItem(title: appState.permissionStatus.label, action: #selector(openPermissions), keyEquivalent: "")
        permissionsItem.target = self
        permissionsItem.isEnabled = !appState.isDevelopmentPermissionBypassEnabled
        menu.addItem(permissionsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quitter CleanKey", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func lockNow() {
        appState.lockNow()
    }

    @objc private func openSettings() {
        settingsWindowController.show()
    }

    @objc private func openPermissions() {
        guard !appState.isDevelopmentPermissionBypassEnabled else {
            return
        }

        appState.refreshPermissions(prompt: true)
        appState.openAccessibilitySettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
