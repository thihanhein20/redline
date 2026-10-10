import AppKit
import SwiftUI

/// Settings in a normal window, for when the menu bar icon is hidden (e.g. behind the notch).
@MainActor
final class SettingsWindow {
    private let overlay: OverlayController
    private var window: NSWindow?

    init(overlay: OverlayController) {
        self.overlay = overlay
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        NSApplication.shared.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Redline"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView(overlay: overlay))
        window.setContentSize(window.contentView!.fittingSize)
        window.center()
        return window
    }
}
