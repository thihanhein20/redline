import FrameCounter

/// Frames per second of the hooked game, measured between two calls.
final class FPSService {
    private var previous: (frames: UInt64, time: ContinuousClock.Instant)?

    /// Returns `nil` when no hooked game is running, or on the first sample.
    func fps() -> Double? {
        var frames: UInt64 = 0
        guard frame_counter_read(&frames) else {
            previous = nil
            return nil
        }
        let now = ContinuousClock.now
        defer { previous = (frames, now) }
        guard let previous, frames >= previous.frames else { return nil }
        return Self.fps(frames: frames - previous.frames, elapsed: now - previous.time)
    }

    static func fps(frames: UInt64, elapsed: Duration) -> Double? {
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        guard seconds > 0 else { return nil }
        return Double(frames) / seconds
    }
}
