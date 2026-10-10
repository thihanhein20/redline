import AppKit

/// Wires the stats monitor to the overlay once the app has launched.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = StatsMonitor()
    private let logger = CSVLogger()
    private var overlay: OverlayPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.start()
        monitor.onUpdate = { [logger] in logger.log($0) }
        monitor.start()

        let panel = OverlayPanel(content: OverlayView(monitor: monitor))
        panel.pinToTopLeft()
        panel.orderFrontRegardless()
        overlay = panel
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}
