import AppKit
import SwiftUI

/// Transparent, click-through window that floats above everything, including full-screen games.
final class OverlayPanel: NSPanel {
    private let margin: CGFloat = 12

    init(content: some View) {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true

        let hostingView = NSHostingView(rootView: content)
        contentView = hostingView
        setContentSize(hostingView.fittingSize)
    }

    /// Moves the panel to `corner` of the main screen, clear of the menu bar and Dock.
    func pin(to corner: OverlayCorner) {
        guard let visible = NSScreen.main?.visibleFrame else { return }
        setFrameOrigin(corner.origin(for: frame.size, in: visible, margin: margin))
    }
}
