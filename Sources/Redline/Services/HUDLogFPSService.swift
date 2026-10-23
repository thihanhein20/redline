import AppKit

/// FPS for any Metal game, read from Apple's Metal HUD log lines (see `MetalHUDService`).
/// When several apps report, it follows the one in front. Needs no permissions, but `log stream` only works for admin users.
@MainActor
final class HUDLogFPSService {
    private static let staleAfter: TimeInterval = 2
    private static let predicate =
        #"subsystem == "com.apple.metal.hud" AND eventMessage BEGINSWITH "\#(HUDLogEntry.messagePrefix)""#

    private let logStream = Process()
    private var readTask: Task<Void, Never>?
    private var previous: [Int32: HUDLogEntry] = [:]
    private var warmedUp: Set<Int32> = []
    /// Latest FPS of every app currently reporting.
    private var readings: [Int32: (fps: Double, at: Date)] = [:]

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

    /// FPS of the game being measured: the frontmost reporting app, otherwise the one that reported last.
    /// Apps that exited or stopped reporting for 2 s are dropped.
    func current() -> (fps: Double, processID: Int32)? {
        let now = Date()
        for (processID, reading) in readings where now.timeIntervalSince(reading.at) >= Self.staleAfter || kill(processID, 0) != 0 {
            forget(processID)
        }
        let frontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier
        guard let processID = Self.choose(readings.mapValues(\.at), frontmost: frontmost),
              let reading = readings[processID] else { return nil }
        return (reading.fps, processID)
    }

    nonisolated static func choose(_ lastReported: [Int32: Date], frontmost: Int32?) -> Int32? {
        if let frontmost, lastReported[frontmost] != nil { return frontmost }
        return lastReported.max { $0.value < $1.value }?.key
    }

    private func handle(_ line: String) {
        guard let entry = HUDLogEntry.parse(line) else { return }
        defer { previous[entry.processID] = entry }
        guard let old = previous[entry.processID], let fps = HUDLogEntry.fps(from: old, to: entry) else { return }
        // The first interval after a game starts includes startup frames and reads far too high.
        guard !warmedUp.insert(entry.processID).inserted else { return }
        readings[entry.processID] = (fps, Date())
    }

    private func forget(_ processID: Int32) {
        readings[processID] = nil
        previous[processID] = nil
        warmedUp.remove(processID)
    }
}
