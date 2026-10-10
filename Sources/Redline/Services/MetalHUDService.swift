import Foundation

/// Turns on Apple's Metal Performance HUD for every Metal app launched while Redline runs.
/// Logging makes the HUD write frame counts to the system log, which `HUDLogFPSService` reads.
/// (The HUD must be visible for logging to work.)
/// Set in the per-user launchd environment, so it also clears on logout if Redline crashes.
struct MetalHUDService {
    private static let variables = ["MTL_HUD_ENABLED", "MTL_HUD_LOG_ENABLED"]

    func enable() {
        for variable in Self.variables { launchctl("setenv", variable, "1") }
    }

    func disable() {
        for variable in Self.variables { launchctl("unsetenv", variable) }
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
