import AppKit

/// Command line handling:
///   redline                                  menu bar app + overlay
///   redline run <Game.app> [game args...]   also launch the game with FPS counting, quit when it exits
enum LaunchArguments {
    static func launchGameIfRequested() -> Process? {
        let arguments = CommandLine.arguments.dropFirst()
        guard arguments.first == "run" else { return nil }
        guard let path = arguments.dropFirst().first else { exitWithError("Usage: redline run <Game.app> [game args...]") }

        do {
            return try GameLauncher.launch(path, arguments: Array(arguments.dropFirst(2))) {
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
