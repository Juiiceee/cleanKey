import AppKit
import ApplicationServices
import Foundation

enum PermissionStatus: Equatable {
    case trusted
    case missing

    var label: String {
        switch self {
        case .trusted:
            "Permissions accordées"
        case .missing:
            "Permissions manquantes"
        }
    }
}

final class PermissionManager {
    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func status(prompt: Bool) -> PermissionStatus {
        if prompt {
            let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let options = [key: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options) ? .trusted : .missing
        }

        return AXIsProcessTrusted() ? .trusted : .missing
    }

    func openAccessibilitySettings() {
        openSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func openInputMonitoringSettings() {
        openSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    private func openSettingsPane(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
