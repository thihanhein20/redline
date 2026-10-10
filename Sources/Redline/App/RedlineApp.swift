import AppKit

/// Usage:
///   redline                                  overlay only
///   redline run <Game.app> [game args...]   launch the game with FPS counting, quit when it exits
@main
enum RedlineApp {
    @MainActor
    static func main() {
        let game = launchGameIfRequested()
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // Accessory: no Dock icon, never steals focus from the game.
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(game) { app.run() }
    }

    private static func launchGameIfRequested() -> Process? {
        let arguments = CommandLine.arguments.dropFirst()
        guard arguments.first == "run" else { return nil }
        let gameArguments = arguments.dropFirst(2)
        guard let path = arguments.dropFirst().first else { exitWithError("Usage: redline run <Game.app> [game args...]") }

        do {
            return try GameLauncher.launch(path, arguments: Array(gameArguments)) {
                Task { @MainActor in NSApplication.shared.terminate(nil) }
            }
        } catch {
            exitWithError(error.localizedDescription)
        }
    }

    private static func exitWithError(_ message: String) -> Never {
        FileHandle.standardError.write(Data("redline: \(message)\n".utf8))
        exit(1)
    }
}
