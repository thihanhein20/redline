import Foundation

/// FPS for any Metal game, read from Apple's Metal HUD log lines (see `MetalHUDService`).
/// Needs no permissions, but `log stream` only works for admin users.
@MainActor
final class HUDLogFPSService {
    private static let staleAfter: TimeInterval = 2
    private static let predicate =
        #"subsystem == "com.apple.metal.hud" AND eventMessage BEGINSWITH "\#(HUDLogEntry.messagePrefix)""#

    private let logStream = Process()
    private var readTask: Task<Void, Never>?
    private var previous: [Int32: HUDLogEntry] = [:]
    private var warmedUp: Set<Int32> = []
    private var latest: (fps: Double, processID: Int32, receivedAt: Date)?

    func start() {
        let pipe = Pipe()
        logStream.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        logStream.arguments = ["stream", "--style", "ndjson", "--predicate", Self.predicate]
        logStream.standardOutput = pipe
        logStream.standardError = FileHandle.nullDevice
        do {
            try logStream.run()
        } catch {
            FileHandle.standardError.write(Data("redline: can't read Metal HUD log: \(error.localizedDescription)\n".utf8))
            return
        }
        readTask = Task { [weak self] in
            // Ends quietly if the log stream closes; FPS then falls back to nil.
            do {
                for try await line in pipe.fileHandleForReading.bytes.lines { self?.handle(line) }
            } catch {}
        }
    }

    func stop() {
        readTask?.cancel()
        if logStream.isRunning { logStream.terminate() }
    }

    /// Latest FPS of whichever game reported most recently.
    /// `nil` as soon as that game exits, or if it hasn't reported for 2 s (e.g. paused or minimised).
    func fps() -> Double? {
        guard let latest else { return nil }
        guard kill(latest.processID, 0) == 0, Date().timeIntervalSince(latest.receivedAt) < Self.staleAfter else {
            forget(latest.processID)
            return nil
        }
        return latest.fps
    }

    private func handle(_ line: String) {
        guard let entry = HUDLogEntry.parse(line) else { return }
        defer { previous[entry.processID] = entry }
        guard let old = previous[entry.processID], let fps = HUDLogEntry.fps(from: old, to: entry) else { return }
        // The first interval after a game starts includes startup frames and reads far too high.
        guard !warmedUp.insert(entry.processID).inserted else { return }
        latest = (fps, entry.processID, Date())
    }

    private func forget(_ processID: Int32) {
        latest = nil
        previous[processID] = nil
        warmedUp.remove(processID)
    }
}
