import Carbon
import CleanKeyCore
import Foundation
import os

final class DevelopmentHotKeyController {
    var onPressed: (() -> Void)?
    var onReleased: (() -> Void)?

    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?
    private var shortcut: GlobalShortcut?

    deinit {
        stop()
    }

    func start(shortcut: GlobalShortcut) -> Bool {
        self.shortcut = shortcut

        guard installEventHandlerIfNeeded() else {
            return false
        }

        return registerHotKey(shortcut)
    }

    func updateShortcut(_ shortcut: GlobalShortcut) -> Bool {
        self.shortcut = shortcut
        unregisterHotKey()
        return registerHotKey(shortcut)
    }

    func stop() {
        unregisterHotKey()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    fileprivate func handle(eventKind: UInt32) -> OSStatus {
        switch eventKind {
        case UInt32(kEventHotKeyPressed):
            onPressed?()
        case UInt32(kEventHotKeyReleased):
            onReleased?()
        default:
            break
        }

        return noErr
    }

    private func installEventHandlerIfNeeded() -> Bool {
        if eventHandler != nil {
            return true
        }

        let eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]

        let status = eventTypes.withUnsafeBufferPointer { eventTypesPointer in
            InstallEventHandler(
                GetApplicationEventTarget(),
                developmentHotKeyEventHandler,
                eventTypes.count,
                eventTypesPointer.baseAddress,
                Unmanaged.passUnretained(self).toOpaque(),
                &eventHandler
            )
        }

        if status != noErr {
            AppLogger.eventTap.error("Development hotkey handler installation failed: \(status, privacy: .public).")
            eventHandler = nil
            return false
        }

        return true
    }

    private func registerHotKey(_ shortcut: GlobalShortcut) -> Bool {
        unregisterHotKey()

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: Self.hotKeyID)
        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.modifiers.carbonFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )

        if status != noErr {
            AppLogger.eventTap.error("Development hotkey registration failed: \(status, privacy: .public).")
            hotKey = nil
            return false
        }

        return true
    }

    private func unregisterHotKey() {
        guard let hotKey else {
            return
        }

        UnregisterEventHotKey(hotKey)
        self.hotKey = nil
    }

    private static let signature: OSType = {
        let scalars = Array("CKDV".unicodeScalars)
        return scalars.reduce(OSType(0)) { result, scalar in
            (result << 8) + OSType(scalar.value)
        }
    }()

    private static let hotKeyID: UInt32 = 1
}

private let developmentHotKeyEventHandler: EventHandlerUPP = { _, event, userData in
    guard let event, let userData else {
        return noErr
    }

    let controller = Unmanaged<DevelopmentHotKeyController>
        .fromOpaque(userData)
        .takeUnretainedValue()

    return controller.handle(eventKind: GetEventKind(event))
}

private extension ShortcutModifiers {
    var carbonFlags: UInt32 {
        var flags = UInt32(0)
        if contains(.control) {
            flags |= UInt32(controlKey)
        }
        if contains(.option) {
            flags |= UInt32(optionKey)
        }
        if contains(.command) {
            flags |= UInt32(cmdKey)
        }
        if contains(.shift) {
            flags |= UInt32(shiftKey)
        }
        return flags
    }
}
