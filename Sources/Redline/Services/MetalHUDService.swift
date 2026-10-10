import Foundation

/// Turns on Apple's Metal Performance HUD for every Metal app launched while Redline runs.
/// Logging makes the HUD write frame counts to the system log, which `HUDLogFPSService` reads.
/// (The HUD must be visible for logging to work.)
/// Set in the per-user launchd environment, so it also clears on logout if Redline crashes.
struct MetalHUDService {
    /// Also passed directly to games started by `redline run`, which bypass the launchd environment.
    static let environment = ["MTL_HUD_ENABLED": "1", "MTL_HUD_LOG_ENABLED": "1"]

    func enable() {
        for (variable, value) in Self.environment { launchctl("setenv", variable, value) }
    }

    func disable() {
        for variable in Self.environment.keys { launchctl("unsetenv", variable) }
    }

    private func launchctl(_ arguments: String...) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            FileHandle.standardError.write(Data("redline: Metal HUD toggle failed: \(error.localizedDescription)\n".utf8))
        }
    }
}
