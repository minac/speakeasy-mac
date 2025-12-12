import Foundation
import Carbon
import AppKit

/// Manages global keyboard shortcuts using Carbon Events API
@MainActor
class ShortcutManager {
    private var hotKeys: [UInt32: EventHotKeyRef] = [:]
    private var callbacks: [UInt32: () -> Void] = [:]
    private var nextHotKeyID: UInt32 = 1
    private var eventHandler: EventHandlerRef?

    init() {
        setupEventHandler()
    }

    deinit {
        // Clean up hot keys
        for (_, hotKeyRef) in hotKeys {
            UnregisterEventHotKey(hotKeyRef)
        }
        // Remove event handler
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }

    /// Registers a global keyboard shortcut
    /// - Parameters:
    ///   - shortcut: Shortcut string (e.g., "cmd+shift+p")
    ///   - action: Callback to invoke when shortcut is triggered
    /// - Returns: true if registration succeeded, false otherwise
    @discardableResult
    func register(shortcut: String, action: @escaping () -> Void) -> Bool {
        guard PermissionsManager.hasAccessibilityPermissions() else {
            AppLogger.shortcuts.warning("Accessibility permissions not granted")
            return false
        }

        let (keyCode, modifiers) = parseShortcut(shortcut)
        guard let keyCode = keyCode, let modifiers = modifiers else {
            AppLogger.shortcuts.error("Failed to parse shortcut: \(shortcut)")
            return false
        }

        let currentID = nextHotKeyID
        let hotKeyID = EventHotKeyID(signature: OSType(0x53504B53), // 'SPKS'
                                      id: currentID)
        nextHotKeyID += 1

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(UInt32(keyCode),
                                         modifiers,
                                         hotKeyID,
                                         GetEventDispatcherTarget(),
                                         0,
                                         &hotKeyRef)

        guard status == noErr, let hotKeyRef = hotKeyRef else {
            AppLogger.shortcuts.error("Failed to register hotkey: \(shortcut) (status: \(status))")
            return false
        }

        hotKeys[currentID] = hotKeyRef
        callbacks[currentID] = action

        AppLogger.shortcuts.info("Registered shortcut: \(shortcut)")
        return true
    }

    /// Unregisters all global keyboard shortcuts
    func unregisterAll() {
        for (_, hotKeyRef) in hotKeys {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeys.removeAll()
        callbacks.removeAll()
    }

    // MARK: - Shortcut Parsing

    /// Parses a shortcut string into Carbon key code and modifiers
    /// - Parameter shortcut: String like "cmd+shift+p" or "ctrl+alt+a"
    /// - Returns: Tuple of (keyCode, modifiers) or (nil, nil) if invalid
    func parseShortcut(_ shortcut: String) -> (UInt16?, UInt32?) {
        guard !shortcut.isEmpty else { return (nil, nil) }

        let components = shortcut.lowercased().split(separator: "+").map(String.init)
        guard components.count >= 2 else { return (nil, nil) }

        // Last component is the key character
        let keyChar = components.last!
        guard let keyCode = keyCodeForCharacter(keyChar) else {
            return (nil, nil)
        }

        // Parse modifiers
        var modifiers: UInt32 = 0
        for modifier in components.dropLast() {
            switch modifier {
            case "cmd", "command":
                modifiers |= UInt32(cmdKey)
            case "shift":
                modifiers |= UInt32(shiftKey)
            case "alt", "option":
                modifiers |= UInt32(optionKey)
            case "ctrl", "control":
                modifiers |= UInt32(controlKey)
            default:
                AppLogger.shortcuts.error("Unknown modifier: \(modifier)")
                return (nil, nil)
            }
        }

        guard modifiers != 0 else {
            AppLogger.shortcuts.error("At least one modifier key is required")
            return (nil, nil)
        }

        return (keyCode, modifiers)
    }

    /// Maps a character to its Carbon key code
    /// - Parameter char: Single character string
    /// - Returns: Carbon virtual key code or nil if not found
    func keyCodeForCharacter(_ char: String) -> UInt16? {
        guard char.count == 1 else { return nil }

        let lowerChar = char.lowercased()
        let keyMap: [String: UInt16] = [
            // Letters
            "a": UInt16(kVK_ANSI_A), "b": UInt16(kVK_ANSI_B), "c": UInt16(kVK_ANSI_C),
            "d": UInt16(kVK_ANSI_D), "e": UInt16(kVK_ANSI_E), "f": UInt16(kVK_ANSI_F),
            "g": UInt16(kVK_ANSI_G), "h": UInt16(kVK_ANSI_H), "i": UInt16(kVK_ANSI_I),
            "j": UInt16(kVK_ANSI_J), "k": UInt16(kVK_ANSI_K), "l": UInt16(kVK_ANSI_L),
            "m": UInt16(kVK_ANSI_M), "n": UInt16(kVK_ANSI_N), "o": UInt16(kVK_ANSI_O),
            "p": UInt16(kVK_ANSI_P), "q": UInt16(kVK_ANSI_Q), "r": UInt16(kVK_ANSI_R),
            "s": UInt16(kVK_ANSI_S), "t": UInt16(kVK_ANSI_T), "u": UInt16(kVK_ANSI_U),
            "v": UInt16(kVK_ANSI_V), "w": UInt16(kVK_ANSI_W), "x": UInt16(kVK_ANSI_X),
            "y": UInt16(kVK_ANSI_Y), "z": UInt16(kVK_ANSI_Z),
            // Numbers
            "0": UInt16(kVK_ANSI_0), "1": UInt16(kVK_ANSI_1), "2": UInt16(kVK_ANSI_2),
            "3": UInt16(kVK_ANSI_3), "4": UInt16(kVK_ANSI_4), "5": UInt16(kVK_ANSI_5),
            "6": UInt16(kVK_ANSI_6), "7": UInt16(kVK_ANSI_7), "8": UInt16(kVK_ANSI_8),
            "9": UInt16(kVK_ANSI_9),
            // Special keys
            "space": UInt16(kVK_Space), "return": UInt16(kVK_Return), "escape": UInt16(kVK_Escape),
            "tab": UInt16(kVK_Tab), "delete": UInt16(kVK_Delete)
        ]

        return keyMap[lowerChar]
    }

    // MARK: - Event Handler

    private func setupEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))

        let callback: EventHandlerUPP = { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }

            let manager = Unmanaged<ShortcutManager>.fromOpaque(userData).takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event,
                                           UInt32(kEventParamDirectObject),
                                           UInt32(typeEventHotKeyID),
                                           nil,
                                           MemoryLayout<EventHotKeyID>.size,
                                           nil,
                                           &hotKeyID)

            guard status == noErr else { return status }

            Task { @MainActor in
                manager.callbacks[hotKeyID.id]?()
            }

            return noErr
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetEventDispatcherTarget(),
                            callback,
                            1,
                            &eventType,
                            selfPointer,
                            &eventHandler)
    }
}
