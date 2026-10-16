import AppKit
import Observation

/// Owns the overlay panel and its user settings (corner, visibility), saved between launches.
@MainActor
@Observable
final class OverlayController {
    private static let cornerKey = "overlayCorner"
    private static let visibleKey = "overlayVisible"
    private static let detailKey = "overlayDetail"

    var corner: OverlayCorner {
        didSet {
            UserDefaults.standard.set(corner.rawValue, forKey: Self.cornerKey)
            panel?.pin(to: corner)
        }
    }

    var isVisible: Bool {
        didSet {
            UserDefaults.standard.set(isVisible, forKey: Self.visibleKey)
            applyVisibility()
        }
    }

    var detail: OverlayDetail {
        didSet { UserDefaults.standard.set(detail.rawValue, forKey: Self.detailKey) }
    }

    @ObservationIgnored private let monitor: StatsMonitor
    @ObservationIgnored private var panel: OverlayPanel?

    init(monitor: StatsMonitor) {
        self.monitor = monitor
        corner = UserDefaults.standard.string(forKey: Self.cornerKey).flatMap(OverlayCorner.init) ?? .topLeft
        isVisible = UserDefaults.standard.object(forKey: Self.visibleKey) as? Bool ?? true
        detail = UserDefaults.standard.string(forKey: Self.detailKey).flatMap(OverlayDetail.init) ?? .compact
    }

    /// Creates the panel; call once the app has finished launching.
    func show() {
        let panel = OverlayPanel(content: OverlayView(monitor: monitor, settings: self))
        self.panel = panel
        panel.pin(to: corner)
        applyVisibility()

        // Re-pin when displays change (resolution, external monitor, Dock size) or the overlay grows or shrinks.
        for (name, object) in [(NSApplication.didChangeScreenParametersNotification, nil as AnyObject?),
                               (NSWindow.didResizeNotification, panel)] {
            NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.panel?.pin(to: self.corner)
                }
            }
        }
    }

    private func applyVisibility() {
        if isVisible { panel?.orderFrontRegardless() } else { panel?.orderOut(nil) }
    }
}
