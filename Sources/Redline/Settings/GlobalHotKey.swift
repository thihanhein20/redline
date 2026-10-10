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
}

/// System-wide shortcut via Carbon's RegisterEventHotKey: works in any app, with no Accessibility permission.
// ponytail: one handler per instance and never unregistered; fine for one shortcut that lives as long as the app.
@MainActor
final class GlobalHotKey {
    private let action: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init(_ shortcut: KeyShortcut, action: @escaping () -> Void) {
        self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            // Carbon delivers hot key events on the main thread.
            let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData!).takeUnretainedValue()
            MainActor.assumeIsolated { hotKey.action() }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)

        let id = EventHotKeyID(signature: OSType(0x524C_4E45), id: 1)  // 'RLNE'
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            FileHandle.standardError.write(Data("redline: shortcut \(shortcut.symbol) unavailable (\(status))\n".utf8))
        }
    }
}
