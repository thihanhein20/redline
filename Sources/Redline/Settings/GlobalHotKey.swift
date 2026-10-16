import Carbon.HIToolbox

/// A keyboard shortcut and how it's shown to the user.
struct KeyShortcut {
    let keyCode: UInt32
    let modifiers: UInt32
    let symbol: String

    static let toggleSettings = KeyShortcut(
        keyCode: UInt32(kVK_ANSI_R),
        modifiers: UInt32(controlKey | optionKey),
        symbol: "⌃⌥R"
    )

    static let toggleOverlay = KeyShortcut(
        keyCode: UInt32(kVK_ANSI_O),
        modifiers: UInt32(controlKey | optionKey),
        symbol: "⌃⌥O"
    )

    static let addMarker = KeyShortcut(
        keyCode: UInt32(kVK_ANSI_M),
        modifiers: UInt32(controlKey | optionKey),
        symbol: "⌃⌥M"
    )
}

/// System-wide shortcut via Carbon's RegisterEventHotKey: works in any app, with no Accessibility permission.
// ponytail: never unregistered; fine for shortcuts that live as long as the app.
@MainActor
final class GlobalHotKey {
    private static var nextID: UInt32 = 1

    private let id: UInt32
    private let action: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init(_ shortcut: KeyShortcut, action: @escaping () -> Void) {
        id = Self.nextID
        Self.nextID += 1
        self.action = action

        // Every handler sees every hot key press, so each one checks the ID and passes on presses that aren't its own.
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            var pressed = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &pressed)
            // Carbon delivers hot key events on the main thread.
            let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData!).takeUnretainedValue()
            return MainActor.assumeIsolated {
                guard pressed.id == hotKey.id else { return OSStatus(eventNotHandledErr) }
                hotKey.action()
                return noErr
            }
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)

        let hotKeyID = EventHotKeyID(signature: OSType(0x524C_4E45), id: id)  // 'RLNE'
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            FileHandle.standardError.write(Data("redline: shortcut \(shortcut.symbol) unavailable (\(status))\n".utf8))
        }
    }
}
