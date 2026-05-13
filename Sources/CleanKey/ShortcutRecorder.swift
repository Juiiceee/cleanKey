import AppKit
import CleanKeyCore
import Foundation

final class ShortcutRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published var message: String?

    private var monitor: Any?

    func start(onCapture: @escaping (GlobalShortcut) -> Void) {
        stop()
        message = "Appuie sur le nouveau raccourci."
        isRecording = true

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else {
                return event
            }

            if event.keyCode == 53 {
                self.stop()
                return nil
            }

            let shortcut = GlobalShortcut(
                keyCode: UInt16(event.keyCode),
                modifiers: ShortcutModifiers(eventFlags: event.modifierFlags)
            )

            guard shortcut.isValidForGlobalUse else {
                self.message = "Utilise au moins Control, Option ou Command avec une touche."
                return nil
            }

            onCapture(shortcut)
            self.stop()
            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isRecording = false
        if message == "Appuie sur le nouveau raccourci." {
            message = nil
        }
    }
}
