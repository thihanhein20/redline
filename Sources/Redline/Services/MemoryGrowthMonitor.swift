/// Turns once-a-second memory readings into a growth rate and a cautious status.
struct MemoryGrowthMonitor {
    /// Skips the start-up load. Later loading still shows as growth, which is why one window isn't called a leak.
    static let warmUpSeconds = 10
    static let thresholdMBPerMinute = 10.0
    /// A single loading jump stays in the 60-second window for at most 60 seconds, so it can never last this long.
    static let leakAfterSeconds = 180

    /// The last minute of readings (warm-up and gaps are `nil`), also drawn as the overlay's memory graph.
    private(set) var history = History(capacity: 60)
    private(set) var growthMBPerMinute: Double?
    /// How long growth has stayed above the threshold without a break.
    private(set) var sustainedSeconds = 0
    private var seconds = 0

    var status: MemoryGrowthStatus {
        if sustainedSeconds >= Self.leakAfterSeconds { return .possibleLeak }
        return sustainedSeconds > 0 ? .growing : .stable
    }

    mutating func add(_ memoryMB: Double) {
        seconds += 1
        history.append(seconds > Self.warmUpSeconds ? memoryMB : nil)
        growthMBPerMinute = MemoryTrend.growthPerMinute(history.values.compactMap { $0 })
        if let growth = growthMBPerMinute, growth >= Self.thresholdMBPerMinute {
            sustainedSeconds += 1
        } else {
            sustainedSeconds = 0
        }
    }

    /// A second without a reading (e.g. no game): a gap in the graph, nothing else changes.
    mutating func addGap() {
        history.append(nil)
    }
}
