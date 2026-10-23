import Foundation

/// Starts a game with RedlineHook.dylib injected so its frames can be counted.
enum GameLauncher {
    static let hookFileName = "libRedlineHook.dylib"

    enum LaunchError: LocalizedError {
        case hookNotBuilt(URL)
        case executableNotFound(URL)
        case iOSApp(URL)

        var errorDescription: String? {
            switch self {
            case .hookNotBuilt(let url): "\(url.path) not found. Run `swift build` first."
            case .executableNotFound(let url): "No executable found in \(url.path)."
            case .iOSApp(let url):
                "\(url.lastPathComponent) is an iPhone/iPad app; macOS only lets it start normally. "
                + "Run `redline` without `run`, then open the game from Finder."
            }
        }
    }

    /// `path` can be a `.app` bundle or the game binary itself. `arguments` are passed to the game.
    /// Apple HUD lines from the game's output go to `onHUDLine`; everything else to Redline's stderr,
    /// so the game's own output never ends up in the CSV on stdout.
    static func launch(_ path: String, arguments: [String], onHUDLine: @escaping @Sendable (String) -> Void,
                       onExit: @escaping @Sendable () -> Void) throws -> Process {
        let process = Process()
        process.executableURL = try executableURL(for: URL(fileURLWithPath: path))
        process.arguments = arguments
        // Hook for frame-by-frame FPS; Metal HUD as the fallback when macOS blocks the hook.
        process.environment = ProcessInfo.processInfo.environment
            .merging(MetalHUDService.environment) { $1 }
            .merging(["DYLD_INSERT_LIBRARIES": try hookURL().path]) { $1 }
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        Task.detached {
            do {
                for try await line in output.fileHandleForReading.bytes.lines {
                    if line.contains("metal-HUD:") { onHUDLine(line) }
                    else if !isHUDNoise(line) { FileHandle.standardError.write(Data((line + "\n").utf8)) }
                }
            } catch {}
        }
        process.terminationHandler = { game in
            FileHandle.standardError.write(Data("redline: game exited (status \(game.terminationStatus))\n".utf8))
            onExit()
        }
        try process.run()
        return process
    }

    /// Harmless warnings Apple's HUD prints at startup in every game; hidden so the game's real output stands out.
    static func isHUDNoise(_ line: String) -> Bool {
        line.contains("[libMTLHud]") || line.contains("NSEventModifierFlagFunction specified")
    }

    private static func hookURL() throws -> URL {
        let url = Bundle.main.executableURL!.resolvingSymlinksInPath()
            .deletingLastPathComponent().appendingPathComponent(hookFileName)
        guard FileManager.default.fileExists(atPath: url.path) else { throw LaunchError.hookNotBuilt(url) }
        return url
    }

    private static func executableURL(for url: URL) throws -> URL {
        guard url.pathExtension == "app" else { return url }
        // iPhone/iPad apps on Apple Silicon are wrapped: Game.app/Wrapper/Game.app
        if FileManager.default.fileExists(atPath: url.appendingPathComponent("Wrapper").path) {
            throw LaunchError.iOSApp(url)
        }
        guard let executable = Bundle(url: url)?.executableURL else { throw LaunchError.executableNotFound(url) }
        return executable
    }
}
