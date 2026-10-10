import AppKit

/// App lifecycle: starts monitoring, the overlay and the Metal HUD; cleans up on quit.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlay: OverlayController

    private lazy var settingsWindow = SettingsWindow(overlay: overlay)
    private let monitor = StatsMonitor()
    private let logger = CSVLogger()
    private let metalHUD = MetalHUDService()
    private var game: Process?
    private var hotKey: GlobalHotKey?
    private var signalSources: [DispatchSourceSignal] = []

    override init() {
        overlay = OverlayController(monitor: monitor)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Accessory: menu bar only, no Dock icon, never steals focus from the game.
        NSApplication.shared.setActivationPolicy(.accessory)
        quitCleanlyOnSignals()
        metalHUD.enable()
        game = LaunchArguments.launchGameIfRequested()

        logger.start()
        monitor.onUpdate = { [logger] in logger.log($0) }
        monitor.start()
        overlay.show()
        hotKey = GlobalHotKey(.toggleSettings) { [weak self] in self?.settingsWindow.toggle() }
        // Opened by the user (not via `redline run`): show settings so they're findable without the menu bar icon.
        if game == nil { settingsWindow.show() }
    }

    /// Opening Redline again while it runs (Finder, Launchpad, Spotlight) brings settings back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow.show()
        return false
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
