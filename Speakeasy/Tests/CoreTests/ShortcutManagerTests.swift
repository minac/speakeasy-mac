import XCTest
import Carbon
@testable import Speakeasy

@MainActor
final class ShortcutManagerTests: XCTestCase {
    var manager: ShortcutManager!

    override func setUp() async throws {
        manager = ShortcutManager()
    }

    override func tearDown() async throws {
        manager.unregisterAll()
        manager = nil
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(manager)
    }

    // MARK: - Shortcut Parsing Tests

    func testParseShortcut_CmdShiftP() {
        let (keyCode, modifiers) = manager.parseShortcut("cmd+shift+p")
        XCTAssertNotNil(keyCode)
        XCTAssertNotNil(modifiers)
        if let modifiers = modifiers {
            XCTAssertTrue(modifiers & UInt32(cmdKey) != 0, "Should include Command modifier")
            XCTAssertTrue(modifiers & UInt32(shiftKey) != 0, "Should include Shift modifier")
        }
    }

    func testParseShortcut_CmdR() {
        let (keyCode, modifiers) = manager.parseShortcut("cmd+r")
        XCTAssertNotNil(keyCode)
        XCTAssertNotNil(modifiers)
        if let modifiers = modifiers {
            XCTAssertTrue(modifiers & UInt32(cmdKey) != 0, "Should include Command modifier")
            XCTAssertFalse(modifiers & UInt32(shiftKey) != 0, "Should not include Shift modifier")
        }
    }

    func testParseShortcut_CmdAltCtrlS() {
        let (keyCode, modifiers) = manager.parseShortcut("cmd+alt+ctrl+s")
        XCTAssertNotNil(keyCode)
        XCTAssertNotNil(modifiers)
        if let modifiers = modifiers {
            XCTAssertTrue(modifiers & UInt32(cmdKey) != 0, "Should include Command modifier")
            XCTAssertTrue(modifiers & UInt32(optionKey) != 0, "Should include Option modifier")
            XCTAssertTrue(modifiers & UInt32(controlKey) != 0, "Should include Control modifier")
        }
    }

    func testParseShortcut_InvalidFormat() {
        let (keyCode, modifiers) = manager.parseShortcut("invalid")
        XCTAssertNil(keyCode, "Should return nil for invalid shortcut")
        XCTAssertNil(modifiers, "Should return nil for invalid shortcut")
    }

    func testParseShortcut_EmptyString() {
        let (keyCode, modifiers) = manager.parseShortcut("")
        XCTAssertNil(keyCode)
        XCTAssertNil(modifiers)
    }

    // MARK: - Registration Tests

    func testRegisterShortcut() {
        var callbackInvoked = false
        let callback = {
            callbackInvoked = true
        }

        let success = manager.register(shortcut: "cmd+shift+t", action: callback)

        // Note: This will only succeed if accessibility permissions are granted
        // In CI/testing environments without permissions, this will be false
        if PermissionsManager.hasAccessibilityPermissions() {
            XCTAssertTrue(success, "Should successfully register with permissions")
        } else {
            XCTAssertFalse(success, "Should fail without permissions")
        }
    }

    func testRegisterShortcut_InvalidShortcut() {
        let callback = {}
        let success = manager.register(shortcut: "invalid", action: callback)
        XCTAssertFalse(success, "Should fail with invalid shortcut string")
    }

    func testUnregisterAll() {
        // Register a shortcut
        _ = manager.register(shortcut: "cmd+shift+t", action: {})

        // Unregister all
        manager.unregisterAll()

        // Should be able to register the same shortcut again
        let success = manager.register(shortcut: "cmd+shift+t", action: {})

        if PermissionsManager.hasAccessibilityPermissions() {
            XCTAssertTrue(success, "Should successfully re-register after unregisterAll")
        }
    }

    // MARK: - Key Code Mapping Tests

    func testKeyCodeForCharacter() {
        XCTAssertEqual(manager.keyCodeForCharacter("a"), kVK_ANSI_A)
        XCTAssertEqual(manager.keyCodeForCharacter("p"), kVK_ANSI_P)
        XCTAssertEqual(manager.keyCodeForCharacter("r"), kVK_ANSI_R)
        XCTAssertEqual(manager.keyCodeForCharacter("s"), kVK_ANSI_S)
        XCTAssertEqual(manager.keyCodeForCharacter("1"), kVK_ANSI_1)
        XCTAssertEqual(manager.keyCodeForCharacter("0"), kVK_ANSI_0)
    }

    func testKeyCodeForCharacter_InvalidCharacter() {
        XCTAssertNil(manager.keyCodeForCharacter("@"))
        XCTAssertNil(manager.keyCodeForCharacter(""))
    }
}
