import AppKit
import Observation

/// Owns the overlay panel and its user settings (corner, visibility), saved between launches.
@MainActor
@Observable
final class OverlayController {
    private static let cornerKey = "overlayCorner"
    private static let visibleKey = "overlayVisible"

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

    @ObservationIgnored private let monitor: StatsMonitor
    @ObservationIgnored private var panel: OverlayPanel?

    init(monitor: StatsMonitor) {
        self.monitor = monitor
        corner = UserDefaults.standard.string(forKey: Self.cornerKey).flatMap(OverlayCorner.init) ?? .topLeft
        isVisible = UserDefaults.standard.object(forKey: Self.visibleKey) as? Bool ?? true
    }

    /// Creates the panel; call once the app has finished launching.
    func show() {
        let panel = OverlayPanel(content: OverlayView(monitor: monitor))
        self.panel = panel
        panel.pin(to: corner)
        applyVisibility()

        // Re-pin when displays change (resolution, external monitor, Dock size).
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.panel?.pin(to: self.corner)
            }
        }
    }

    private func applyVisibility() {
        if isVisible { panel?.orderFrontRegardless() } else { panel?.orderOut(nil) }
    }
}
