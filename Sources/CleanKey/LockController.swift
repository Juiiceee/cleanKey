import CleanKeyCore
import CoreGraphics
import Foundation
import os

final class LockController: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var unlockProgress = 0.0
    @Published private(set) var isUnlockHoldActive = false
    @Published private(set) var unlockRemainingSeconds = 0
    @Published private(set) var autoUnlockRemainingSeconds = 0
    @Published private(set) var isReleaseGuardActive = false
    @Published private(set) var releaseGuardRemainingSeconds = 0
    @Published private(set) var isEventTapRunning = false
    @Published var lastError: String?

    private let eventTapController = EventTapController()
    private var settings: AppSettings
    private var heldKeyCodes = Set<UInt16>()
    private var currentModifiers: ShortcutModifiers = []
    private(set) var lockStartedAt: Date?
    private(set) var unlockStartedAt: Date?
    private(set) var unlockDeadline: Date?
    private(set) var autoUnlockDeadline: Date?
    private(set) var releaseGuardStartedAt: Date?
    private(set) var releaseGuardDeadline: Date?
    private var unlockTimer: Timer?
    private var autoUnlockTimer: Timer?
    private var autoUnlockTickTimer: Timer?
    private var releaseGuardTimer: Timer?
    private var releaseGuardTickTimer: Timer?

    var unlockHoldDuration: TimeInterval {
        settings.unlockHoldDuration
    }

    var autoUnlockDuration: TimeInterval {
        settings.autoUnlockDuration
    }

    var releaseGuardDuration: TimeInterval {
        1
    }

    init(settings: AppSettings) {
        var settings = settings
        settings.enforceSafetyLimits()
        self.settings = settings
        eventTapController.delegate = self
    }

    func startEventTap() -> Bool {
        let didStart = eventTapController.start()
        isEventTapRunning = didStart
        if !didStart {
            lastError = "Interception macOS indisponible. Vérifie les permissions Accessibilité."
        }
        AppLogger.lock.info("Start event tap result: \(didStart, privacy: .public).")
        return didStart
    }

    func stopEventTap() {
        eventTapController.stop()
        isEventTapRunning = false
    }

    func updateSettings(_ settings: AppSettings) {
        var settings = settings
        settings.enforceSafetyLimits()
        self.settings = settings
        cancelUnlockHold()
    }

    func lock() {
        guard isEventTapRunning else {
            lastError = "CleanKey ne peut pas verrouiller sans intercepteur d'événements."
            AppLogger.lock.error("Lock refused because event tap is not running.")
            return
        }
        guard !isLocked else {
            AppLogger.lock.info("Lock ignored because CleanKey is already locked.")
            return
        }

        resetHeldShortcut()
        cancelReleaseGuard()
        lockStartedAt = Date()
        isLocked = true
        lastError = nil
        scheduleAutoUnlock()
        OverlayController.shared.show(lockController: self, shortcut: settings.shortcut)
        AppLogger.lock.info(
            "Locked. Auto unlock duration: \(self.settings.autoUnlockDuration, privacy: .public)s."
        )
    }

    func unlock() {
        finishUnlock()
    }

    private func beginReleaseGuard() {
        guard isLocked else {
            return
        }

        cancelUnlockHold(resetProgress: false)
        cancelAutoUnlock()
        heldKeyCodes.removeAll()
        currentModifiers = []
        isReleaseGuardActive = true
        releaseGuardStartedAt = Date()
        releaseGuardDeadline = Date().addingTimeInterval(releaseGuardDuration)
        updateReleaseGuardRemainingSeconds()

        releaseGuardTimer = scheduleTimer(withTimeInterval: releaseGuardDuration, repeats: false) { [weak self] _ in
            self?.finishUnlock()
        }
        releaseGuardTickTimer = scheduleTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateReleaseGuardRemainingSeconds()
        }
        AppLogger.lock.info("Release guard started.")
    }

    private func finishUnlock() {
        guard isLocked || isReleaseGuardActive else {
            return
        }

        isLocked = false
        cancelUnlockHold()
        cancelAutoUnlock()
        cancelReleaseGuard()
        resetHeldShortcut()
        lockStartedAt = nil
        OverlayController.shared.hide()
        AppLogger.lock.info("Unlocked.")
    }

    private func scheduleAutoUnlock() {
        cancelAutoUnlock()
        autoUnlockDeadline = Date().addingTimeInterval(settings.autoUnlockDuration)
        updateAutoUnlockRemainingSeconds()

        autoUnlockTimer = scheduleTimer(withTimeInterval: settings.autoUnlockDuration, repeats: false) { [weak self] _ in
            self?.finishUnlock()
        }
        autoUnlockTickTimer = scheduleTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tickAutoUnlock()
        }
    }

    private func cancelAutoUnlock() {
        autoUnlockTimer?.invalidate()
        autoUnlockTickTimer?.invalidate()
        autoUnlockTimer = nil
        autoUnlockTickTimer = nil
        autoUnlockDeadline = nil
        autoUnlockRemainingSeconds = 0
    }

    private func tickAutoUnlock() {
        updateAutoUnlockRemainingSeconds()
        if autoUnlockRemainingSeconds <= 0 {
            finishUnlock()
        }
    }

    private func updateAutoUnlockRemainingSeconds() {
        guard let autoUnlockDeadline else {
            autoUnlockRemainingSeconds = 0
            return
        }

        autoUnlockRemainingSeconds = max(0, Int(ceil(autoUnlockDeadline.timeIntervalSinceNow)))
    }

    private func resetHeldShortcut() {
        heldKeyCodes.removeAll()
        currentModifiers = []
        cancelUnlockHold()
    }

    private func cancelReleaseGuard() {
        releaseGuardTimer?.invalidate()
        releaseGuardTickTimer?.invalidate()
        releaseGuardTimer = nil
        releaseGuardTickTimer = nil
        releaseGuardStartedAt = nil
        releaseGuardDeadline = nil
        isReleaseGuardActive = false
        releaseGuardRemainingSeconds = 0
    }

    private func updateReleaseGuardRemainingSeconds() {
        guard let releaseGuardDeadline else {
            releaseGuardRemainingSeconds = 0
            return
        }

        releaseGuardRemainingSeconds = max(0, Int(ceil(releaseGuardDeadline.timeIntervalSinceNow)))
    }

    private func processShortcutHold(event: CGEvent, type: CGEventType) {
        let eventKeyCode = keyCode(from: event)
        let eventModifiers = ShortcutModifiers(cgFlags: event.flags)

        switch type {
        case .keyDown:
            heldKeyCodes.insert(eventKeyCode)
            currentModifiers = eventModifiers
        case .keyUp:
            heldKeyCodes.remove(eventKeyCode)
            currentModifiers = eventModifiers
        case .flagsChanged:
            currentModifiers = eventModifiers
        default:
            break
        }

        if isUnlockShortcutHeld {
            startUnlockHoldIfNeeded()
        } else {
            cancelUnlockHold()
        }
    }

    private var isUnlockShortcutHeld: Bool {
        heldKeyCodes.contains(settings.shortcut.keyCode) && currentModifiers.containsAll(settings.shortcut.modifiers)
    }

    private func startUnlockHoldIfNeeded() {
        guard unlockStartedAt == nil else {
            return
        }

        unlockStartedAt = Date()
        unlockDeadline = Date().addingTimeInterval(settings.unlockHoldDuration)
        isUnlockHoldActive = true
        unlockProgress = 0
        unlockRemainingSeconds = Int(ceil(settings.unlockHoldDuration))
        unlockTimer = scheduleTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tickUnlockHold()
        }
        AppLogger.lock.info(
            "Unlock hold started. Required duration: \(self.settings.unlockHoldDuration, privacy: .public)s."
        )
    }

    private func tickUnlockHold() {
        guard let unlockStartedAt else {
            return
        }

        let elapsed = Date().timeIntervalSince(unlockStartedAt)
        unlockProgress = min(1, elapsed / settings.unlockHoldDuration)
        unlockRemainingSeconds = max(0, Int(ceil(settings.unlockHoldDuration - elapsed)))
        if elapsed >= settings.unlockHoldDuration {
            beginReleaseGuard()
        }
    }

    private func cancelUnlockHold(resetProgress: Bool = true) {
        unlockTimer?.invalidate()
        unlockTimer = nil
        unlockStartedAt = nil
        unlockDeadline = nil
        isUnlockHoldActive = false
        if resetProgress {
            unlockProgress = 0
        }
        unlockRemainingSeconds = 0
    }

    private func scheduleTimer(
        withTimeInterval timeInterval: TimeInterval,
        repeats: Bool,
        block: @escaping (Timer) -> Void
    ) -> Timer {
        let timer = Timer(timeInterval: timeInterval, repeats: repeats, block: block)
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    private func keyCode(from event: CGEvent) -> UInt16 {
        UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    }
}

extension LockController: EventTapControllerDelegate {
    func eventTapController(_ controller: EventTapController, shouldConsume event: CGEvent, type: CGEventType) -> Bool {
        if isLocked {
            if isReleaseGuardActive {
                return true
            }
            processShortcutHold(event: event, type: type)
            return true
        }

        guard type == .keyDown else {
            return false
        }

        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        guard !isRepeat, settings.shortcut.matches(keyCode: keyCode(from: event), flags: event.flags) else {
            return false
        }

        lock()
        processShortcutHold(event: event, type: type)
        return true
    }

    func eventTapControllerWasReenabled(_ controller: EventTapController) {
        isEventTapRunning = true
    }
}
