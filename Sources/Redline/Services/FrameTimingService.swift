import FrameCounter

/// Per-frame timing from the hook (games launched with `redline run`): 1% low FPS, stutters, frame times.
final class FrameTimingService {
    private static let windowNanoseconds: UInt64 = 10_000_000_000
    private static let graphFrames = 120

    private var lastFrame: UInt64 = 0
    private var lastTime: UInt64?
    private var recent: [(end: UInt64, ms: Double)] = []
    private var stutters = 0
    private var inStutter = false
    private var session = FrameTimeHistogram()
    private var buffer = [UInt64](repeating: 0, count: 1024)

    func sample() -> FramePacing? {
        var total: UInt64 = 0
        guard frame_counter_read(&total) else { reset(); return nil }
        if total < lastFrame { reset() }  // the game restarted

        var newest: UInt64 = 0
        let count = Int(frame_counter_copy_times(lastFrame, &buffer, buffer.count, &newest))
        // Only join onto the previous frame if no frames were skipped in between.
        var previous = newest - UInt64(count) == lastFrame ? lastTime : nil
        let median = Self.median(recent.map(\.ms))
        var newFrames: [Double] = []
        for time in buffer.prefix(count) {
            if let previous, time > previous {
                let ms = Double(time - previous) / 1_000_000
                newFrames.append(ms)
                recent.append((time, ms))
                session.add(ms)
            }
            previous = time
        }
        stutters += Self.stutterEvents(in: newFrames, median: median, alreadyStuttering: &inStutter)
        if count > 0 { lastFrame = newest; lastTime = buffer[count - 1] }
        if let lastTime { recent.removeAll { $0.end + Self.windowNanoseconds < lastTime } }

        let times = recent.map(\.ms)
        return FramePacing(onePercentLowFPS: Self.onePercentLow(times), sessionOnePercentLowFPS: session.onePercentLowFPS,
                           stutters: stutters, frameTimesMS: Array(times.suffix(Self.graphFrames)))
    }

    private func reset() {
        lastFrame = 0
        lastTime = nil
        recent.removeAll()
        stutters = 0
        inStutter = false
        session = FrameTimeHistogram()
    }

    /// Average FPS of the slowest 1% of frames (at least one), as benchmark tools like CapFrameX report it.
    static func onePercentLow(_ frameTimesMS: [Double]) -> Double? {
        guard frameTimesMS.count >= 20 else { return nil }
        let slowest = frameTimesMS.sorted(by: >).prefix(max(1, frameTimesMS.count / 100))
        let averageMS = slowest.reduce(0, +) / Double(slowest.count)
        return averageMS > 0 ? 1000 / averageMS : nil
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.sorted()[values.count / 2]
    }

    /// A frame that took more than twice as long as a typical one (needs a few seconds of history first).
    static func isStutter(_ ms: Double, median: Double?) -> Bool {
        guard let median, median > 0 else { return false }
        return ms > median * 2
    }

    /// Counts hitches: a run of slow frames in a row is one stutter, not one per frame.
    static func stutterEvents(in frameTimesMS: [Double], median: Double?, alreadyStuttering: inout Bool) -> Int {
        var events = 0
        for ms in frameTimesMS {
            let slow = isStutter(ms, median: median)
            if slow && !alreadyStuttering { events += 1 }
            alreadyStuttering = slow
        }
        return events
    }
}
