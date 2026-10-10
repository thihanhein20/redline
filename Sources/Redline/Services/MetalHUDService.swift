import Foundation

/// Turns on Apple's Metal Performance HUD (exact in-game FPS) for every Metal app launched while Redline runs.
/// Set in the per-user launchd environment, so it also clears on logout if Redline crashes.
struct MetalHUDService {
    private static let variable = "MTL_HUD_ENABLED"

    func enable() {
        launchctl("setenv", Self.variable, "1")
    }

    func disable() {
        launchctl("unsetenv", Self.variable)
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
