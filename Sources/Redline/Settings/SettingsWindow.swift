import AppKit
import SwiftUI

/// Settings in a normal window, for when the menu bar icon is hidden (e.g. behind the notch).
@MainActor
final class SettingsWindow {
    private let overlay: OverlayController
    private let sessions: SessionRecorder
    private var window: NSWindow?

    init(overlay: OverlayController, sessions: SessionRecorder) {
        self.overlay = overlay
        self.sessions = sessions
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        NSApplication.shared.activate()
        window.makeKeyAndOrderFront(nil)
    }

    /// Closes the window if it's in front, otherwise shows it.
    func toggle() {
        if let window, window.isKeyWindow {
            window.close()
        } else {
            show()
        }
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Redline"
        window.isReleasedWhenClosed = false
        // The window follows the view's size (e.g. when a "Last Session" section appears).
        let controller = NSHostingController(rootView: SettingsView(overlay: overlay, sessions: sessions))
        controller.sizingOptions = .preferredContentSize
        window.contentViewController = controller
        window.center()
        return window
    }
}
