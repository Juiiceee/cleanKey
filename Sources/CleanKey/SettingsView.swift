import CleanKeyCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var lockController: LockController
    @StateObject private var shortcutRecorder = ShortcutRecorder()

    init(appState: AppState) {
        self.appState = appState
        _lockController = ObservedObject(wrappedValue: appState.lockController)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            Divider()
            shortcutSection
            launchSection
            permissionsSection
            aboutSection
            uninstallSection
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 520)
        .onDisappear {
            shortcutRecorder.stop()
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "keyboard")
                .font(.system(size: 34, weight: .medium))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("CleanKey")
                    .font(.title2.weight(.semibold))
                Text(lockController.isLocked ? "Entrées verrouillées" : "Prêt à verrouiller")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Verrouiller") {
                appState.lockNow()
            }
            .disabled(lockController.isLocked)
        }
    }

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Raccourci")
            HStack {
                Text(appState.settings.shortcut.displayString)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

                Spacer()

                Button(shortcutRecorder.isRecording ? "En attente..." : "Modifier") {
                    shortcutRecorder.start { shortcut in
                        appState.updateShortcut(shortcut)
                    }
                }
            }

            if let message = shortcutRecorder.message ?? appState.lastError {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var launchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Démarrage")
            Toggle(
                "Lancer CleanKey au démarrage",
                isOn: Binding(
                    get: { appState.launchAtLoginEnabled },
                    set: { appState.setLaunchAtLogin($0) }
                )
            )
        }
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Permissions")
            HStack {
                Label(appState.permissionStatus.label, systemImage: appState.permissionStatus == .trusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(appState.permissionStatus == .trusted ? .green : .orange)

                Spacer()

                Button("Vérifier") {
                    appState.refreshPermissions(prompt: false)
                }
                Button("Accessibilité") {
                    appState.openAccessibilitySettings()
                }
                Button("Input Monitoring") {
                    appState.openInputMonitoringSettings()
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("À propos")
            HStack {
                Text("Version \(appState.version)")
                Spacer()
                Link("Code open source", destination: appState.sourceURL)
            }
            Text("Sécurité: un verrouillage dure 3 minutes maximum, même si le raccourci de déverrouillage ne répond pas.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var uninstallSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Désinstallation")
            Text("Désactive le lancement au démarrage, quitte CleanKey, puis supprime CleanKey.app du dossier Applications. Pour effacer les réglages: `defaults delete dev.loul.CleanKey`.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }
}
