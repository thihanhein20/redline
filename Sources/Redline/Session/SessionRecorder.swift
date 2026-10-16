import Foundation
import Observation

/// Turns the stream of readings into play sessions: one starts when a game reports FPS
/// and ends after a few seconds without it (or when Redline quits).
@MainActor
@Observable
final class SessionRecorder {
    private static let endAfterQuietSeconds = 3
    private static let minimumSeconds = 5  // shorter blips aren't worth a summary

    private(set) var last: SessionSummary?
    @ObservationIgnored private var current: SessionSummary?
    @ObservationIgnored private var quietSeconds = 0

    func record(_ stats: SystemStats) {
        guard stats.fps != nil else {
            quietSeconds += 1
            if quietSeconds >= Self.endAfterQuietSeconds { finish() }
            return
        }
        quietSeconds = 0
        if current == nil { current = SessionSummary() }
        current?.add(stats)
    }

    /// Ends the current session and prints its summary to stderr (the Terminal, or the Unity log).
    func finish() {
        defer { current = nil }
        guard let current, current.seconds >= Self.minimumSeconds else { return }
        last = current
        FileHandle.standardError.write(Data((SessionReport.text(for: current) + "\n").utf8))
    }
}
