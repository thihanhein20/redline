import AppKit

/// Wires the stats monitor to the overlay once the app has launched.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = StatsMonitor()
    private let logger = CSVLogger()
    private let metalHUD = MetalHUDService()
    private var overlay: OverlayPanel?
    private var signalSources: [DispatchSourceSignal] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        quitCleanlyOnSignals()
        metalHUD.enable()

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
        metalHUD.disable()
    }

    /// Ctrl-C / kill would skip `applicationWillTerminate` and leave the Metal HUD on; route them through it.
    private func quitCleanlyOnSignals() {
        for signalNumber in [SIGINT, SIGTERM] {
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler {
                MainActor.assumeIsolated { NSApplication.shared.terminate(nil) }
            }
            source.resume()
            signalSources.append(source)
        }
    }
}
