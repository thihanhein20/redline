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

    /// Places the panel in the top-left corner of the main screen.
    func pinToTopLeft() {
        guard let visible = NSScreen.main?.visibleFrame else { return }
        setFrameOrigin(NSPoint(x: visible.minX + margin, y: visible.maxY - frame.height - margin))
    }
}
