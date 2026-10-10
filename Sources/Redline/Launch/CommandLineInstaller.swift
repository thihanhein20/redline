import Foundation

/// Installs a `redline` command in /usr/local/bin (on every Mac's default PATH), so developers can run
/// `redline run ./Builds/MyGame.app` from any folder. Asks for an admin password, like VS Code's `code`.
enum CommandLineInstaller {
    static let commandPath = "/usr/local/bin/redline"

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: commandPath)
    }

    /// A tiny script rather than a symlink, so the binary runs from inside Redline.app
    /// (finding the hook next to it and using the app's settings).
    static func script(executable: String) -> String {
        "#!/bin/sh\nexec \"\(executable)\" \"$@\"\n"
    }

    /// Returns an error message, or `nil` on success.
    @MainActor
    static func install() -> String? {
        let executable = Bundle.main.executableURL!.resolvingSymlinksInPath().path
        guard !executable.hasPrefix("/Volumes/") else {
            return "Move Redline to Applications first, then install the command."
        }

        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("redline-command")
        do {
            try script(executable: executable).write(to: temp, atomically: true, encoding: .utf8)
        } catch {
            return error.localizedDescription
        }

        let shell = "mkdir -p /usr/local/bin && cp '\(temp.path)' '\(commandPath)' && chmod 755 '\(commandPath)'"
        var error: NSDictionary?
        NSAppleScript(source: "do shell script \"\(shell)\" with administrator privileges")?.executeAndReturnError(&error)
        guard let error else { return nil }
        // -128: the user cancelled the password prompt.
        return (error[NSAppleScript.errorNumber] as? Int) == -128 ? "Cancelled." : "\(error[NSAppleScript.errorMessage] ?? "Install failed.")"
    }
}
