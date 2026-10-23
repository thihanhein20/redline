/// Frame-by-frame smoothness for games launched with `redline run`.
struct FramePacing {
    /// FPS of the slowest 1% of frames over the last 10 seconds: the standard stutter number.
    var onePercentLowFPS: Double?
    /// The same, over every frame since the game started.
    var sessionOnePercentLowFPS: Double?
    /// Hitches this session: runs of frames that each took more than twice as long as a typical frame.
    /// A run of slow frames in a row counts once.
    var stutters: Int
    /// The most recent frame times (ms), oldest first, for the frame-time graph.
    var frameTimesMS: [Double]
}
