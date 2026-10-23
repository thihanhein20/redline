import Foundation

/// Turns on Apple's Metal Performance HUD for every Metal app launched while Redline runs, hidden,
/// with logging on: the HUD writes frame counts to the system log (read by `HUDLogFPSService`)
/// without drawing anything in the game. Redline's own overlay shows the FPS instead.
/// Set in the per-user launchd environment, so it also clears on logout if Redline crashes.
final class MetalHUDService {
    /// Also passed directly to games started by `redline run`, which bypass the launchd environment.
    static let environment = ["MTL_HUD_ENABLED": "1", "MTL_HUD_LOG_ENABLED": "1", "MTL_HUD_HIDDEN": "1"]

    /// The user's own values from before `enable()` ("" = wasn't set). `nil` until Redline changes anything.
    private var previous: [String: String]?

    func enable() {
        var saved: [String: String] = [:]
        for (variable, value) in Self.environment {
            saved[variable] = launchctl("getenv", variable)
            launchctl("setenv", variable, value)
        }
        previous = saved
    }

    /// Puts back whatever was there before. Does nothing if this copy of Redline never enabled the HUD.
    func disable() {
        guard let previous else { return }
        for arguments in Self.restoreArguments(previous: previous) { launchctl(arguments) }
        self.previous = nil
    }

    static func restoreArguments(previous: [String: String]) -> [[String]] {
        previous.sorted { $0.key < $1.key }.map { variable, value in
            value.isEmpty ? ["unsetenv", variable] : ["setenv", variable, value]
        }
    }

    @discardableResult
    private func launchctl(_ arguments: String...) -> String {
        launchctl(arguments)
    }

    @discardableResult
    private func launchctl(_ arguments: [String]) -> String {
        let process = Process(), output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardOutput = output
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            FileHandle.standardError.write(Data("redline: Metal HUD setting failed: \(error.localizedDescription)\n".utf8))
        }
        return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
