import CoreGraphics
import Foundation
import os

protocol EventTapControllerDelegate: AnyObject {
    func eventTapController(_ controller: EventTapController, shouldConsume event: CGEvent, type: CGEventType) -> Bool
    func eventTapControllerWasReenabled(_ controller: EventTapController)
}

final class EventTapController {
    weak var delegate: EventTapControllerDelegate?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var isRunning: Bool {
        eventTap != nil
    }

    func start() -> Bool {
        if isRunning {
            AppLogger.eventTap.info("Event tap already running.")
            return true
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: Self.eventMask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            AppLogger.eventTap.error("CGEvent tap creation failed.")
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        AppLogger.eventTap.info("Event tap started.")
        return true
    }

    func stop() {
        guard isRunning else {
            return
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        runLoopSource = nil
        eventTap = nil
        AppLogger.eventTap.info("Event tap stopped.")
    }

    fileprivate func reenableIfPossible() {
        guard let eventTap else {
            return
        }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        AppLogger.eventTap.warning("Event tap was disabled by macOS and has been re-enabled.")
        delegate?.eventTapControllerWasReenabled(self)
    }

    fileprivate func shouldConsume(event: CGEvent, type: CGEventType) -> Bool {
        delegate?.eventTapController(self, shouldConsume: event, type: type) ?? false
    }

    private static let eventMask: CGEventMask = {
        var mask = CGEventMask(0)
        let eventTypes: [CGEventType] = [
            .keyDown,
            .keyUp,
            .flagsChanged,
            .leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .mouseMoved,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDown,
            .otherMouseUp,
            .otherMouseDragged,
            .scrollWheel,
            .tabletPointer,
            .tabletProximity
        ]

        for eventType in eventTypes {
            mask |= CGEventMask(1) << CGEventMask(eventType.rawValue)
        }
        return mask
    }()
}

private let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let controller = Unmanaged<EventTapController>
        .fromOpaque(userInfo)
        .takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        controller.reenableIfPossible()
        return Unmanaged.passUnretained(event)
    }

    if controller.shouldConsume(event: event, type: type) {
        return nil
    }

    return Unmanaged.passUnretained(event)
}
