import AppKit

/// Command line handling:
///   redline                                  menu bar app + overlay
///   redline run <Game.app> [game args...]   also launch the game with FPS counting, quit when it exits
///   redline compare <before.csv> <after.csv> print a side-by-side comparison of two runs and exit
enum LaunchArguments {
    static var isRunCommand: Bool {
        CommandLine.arguments.dropFirst().first == "run"
    }

    /// Handles `compare` before the app starts, so no overlay or menu bar icon appears.
    static func compareIfRequested() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard arguments.first == "compare" else { return }
        guard arguments.count == 3 else { exitWithError("Usage: redline compare <before.csv> <after.csv>") }
        let runs = arguments.dropFirst().map { path -> RunMetrics in
            let url = URL(fileURLWithPath: path)
            guard let csv = try? String(contentsOf: url, encoding: .utf8),
                  let run = RunMetrics.parse(csv: csv, name: url.deletingPathExtension().lastPathComponent)
            else { exitWithError("\(path) isn't a Redline CSV log.") }
            return run
        }
        print(CompareReport.text(runs[0], runs[1]))
        exit(0)
    }

    static func launchGameIfRequested(onHUDLine: @escaping @Sendable (String) -> Void) -> Process? {
        let arguments = CommandLine.arguments.dropFirst()
        guard arguments.first == "run" else { return nil }
        guard let path = arguments.dropFirst().first else { exitWithError("Usage: redline run <Game.app> [game args...]") }

        do {
            return try GameLauncher.launch(path, arguments: Array(arguments.dropFirst(2)), onHUDLine: onHUDLine) {
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
