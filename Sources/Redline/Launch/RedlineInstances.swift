import AppKit

/// Knows whether another Redline was already running at launch, so there's only ever one overlay.
enum RedlineInstances {
    static let bundleIdentifier = "com.thihanhein20.redline"

    /// Decided once, at launch. Matches the installed app and builds run from Terminal.
    static let anotherIsRunning: Bool = NSWorkspace.shared.runningApplications.contains { app in
        app.processIdentifier != getpid()
            && (app.bundleIdentifier == bundleIdentifier || app.executableURL?.lastPathComponent == "Redline")
    }

    /// `redline run` while Redline is already open: log only, and leave the overlay and shortcuts to that copy.
    static var isHeadless: Bool {
        LaunchArguments.isRunCommand && anotherIsRunning
    }

    /// A second copy of the app itself has nothing to add.
    static func exitIfDuplicate() {
        guard anotherIsRunning, !LaunchArguments.isRunCommand else { return }
        FileHandle.standardError.write(Data("redline: Redline is already running. Press ⌃⌥R to open its settings.\n".utf8))
        exit(0)
    }
}
