import Foundation

/// Starts a game with RedlineHook.dylib injected so its frames can be counted.
enum GameLauncher {
    static let hookFileName = "libRedlineHook.dylib"

    enum LaunchError: LocalizedError {
        case hookNotBuilt(URL)
        case executableNotFound(URL)

        var errorDescription: String? {
            switch self {
            case .hookNotBuilt(let url): "\(url.path) not found. Run `swift build` first."
            case .executableNotFound(let url): "No executable found in \(url.path)."
            }
        }
    }

    /// `path` can be a `.app` bundle or the game binary itself.
    static func launch(_ path: String, onExit: @escaping @Sendable () -> Void) throws -> Process {
        let process = Process()
        process.executableURL = try executableURL(for: URL(fileURLWithPath: path))
        process.environment = ProcessInfo.processInfo.environment
            .merging(["DYLD_INSERT_LIBRARIES": try hookURL().path]) { $1 }
        process.terminationHandler = { _ in onExit() }
        try process.run()
        return process
    }

    private static func hookURL() throws -> URL {
        let url = Bundle.main.executableURL!.deletingLastPathComponent().appendingPathComponent(hookFileName)
        guard FileManager.default.fileExists(atPath: url.path) else { throw LaunchError.hookNotBuilt(url) }
        return url
    }

    private static func executableURL(for url: URL) throws -> URL {
        guard url.pathExtension == "app" else { return url }
        guard let executable = Bundle(url: url)?.executableURL else { throw LaunchError.executableNotFound(url) }
        return executable
    }
}
