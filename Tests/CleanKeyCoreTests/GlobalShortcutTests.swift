import CleanKeyCore
import XCTest

final class GlobalShortcutTests: XCTestCase {
    func testDefaultShortcut() {
        XCTAssertEqual(GlobalShortcut.defaultShortcut.keyCode, 37)
        XCTAssertEqual(GlobalShortcut.defaultShortcut.modifiers, [.control, .option, .command])
        XCTAssertEqual(GlobalShortcut.defaultShortcut.displayString, "⌃⌥⌘L")
        XCTAssertTrue(GlobalShortcut.defaultShortcut.isValidForGlobalUse)
    }

    func testShiftOnlyShortcutIsRejected() {
        let shortcut = GlobalShortcut(keyCode: 37, modifiers: [.shift])
        XCTAssertFalse(shortcut.isValidForGlobalUse)
    }

    func testModifierOnlyShortcutIsRejected() {
        let shortcut = GlobalShortcut(keyCode: 55, modifiers: [.command])
        XCTAssertFalse(shortcut.isValidForGlobalUse)
    }

    func testSettingsRoundTrip() throws {
        let settings = AppSettings(
            shortcut: GlobalShortcut(keyCode: 8, modifiers: [.command, .option]),
            launchAtLogin: true,
            unlockHoldDuration: 4,
            autoUnlockDuration: 120
        )

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded, settings)
    }

    func testAutoUnlockDurationIsClampedToThreeMinutes() {
        let settings = AppSettings(autoUnlockDuration: 600)
        XCTAssertEqual(settings.autoUnlockDuration, 180)
    }
}
