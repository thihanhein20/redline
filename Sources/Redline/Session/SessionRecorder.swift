import Foundation
import Observation

/// Turns the stream of readings into play sessions: one starts when a game reports FPS
/// and ends after a few seconds without it (or when Redline quits). Optionally saves each one to disk.
@MainActor
@Observable
final class SessionRecorder {
    private static let endAfterQuietSeconds = 3
    private static let minimumSeconds = 5  // shorter blips aren't worth a summary

    private static let savesToDiskKey = "recordSessions"

    private(set) var last: SessionSummary?
    /// Save each session as CSV + summary in `SessionLog.folder`. Takes effect from the next session.
    var savesToDisk = UserDefaults.standard.bool(forKey: savesToDiskKey) {
        didSet { UserDefaults.standard.set(savesToDisk, forKey: Self.savesToDiskKey) }
    }
    @ObservationIgnored private var current: SessionSummary?
    @ObservationIgnored private var log: SessionLog?
    @ObservationIgnored private var quietSeconds = 0

    func record(_ stats: SystemStats) {
        guard stats.fps != nil else {
            quietSeconds += 1
            if quietSeconds >= Self.endAfterQuietSeconds { finish() }
            return
        }
        quietSeconds = 0
        if current == nil {
            current = SessionSummary()
            if savesToDisk { log = SessionLog(game: stats.game?.name, startedAt: Date()) }
        }
        current?.add(stats)
        log?.append(stats)
    }

    /// Ends the current session and prints its summary to stderr (the Terminal, or the Unity log).
    func finish() {
        defer { current = nil; log = nil }
        guard let current, current.seconds >= Self.minimumSeconds else {
            log?.discard()
            return
        }
        last = current
        log?.finish(with: current)
        FileHandle.standardError.write(Data((SessionReport.text(for: current) + "\n").utf8))
    }
}
