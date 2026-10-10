import AppKit

@main
enum RedlineApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // Accessory: no Dock icon, never steals focus from the game.
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
