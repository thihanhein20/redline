/// Frame-by-frame smoothness for games launched with `redline run`.
struct FramePacing {
    /// FPS of the slowest 1% of frames over the last 10 seconds: the standard stutter number.
    var onePercentLowFPS: Double?
    /// Frames this session that took more than twice as long as a typical frame.
    var stutters: Int
    /// The most recent frame times (ms), oldest first, for the frame-time graph.
    var frameTimesMS: [Double]
}
