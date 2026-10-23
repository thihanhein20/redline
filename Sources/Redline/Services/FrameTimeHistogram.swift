/// Every frame time of a game session in 0.1 ms buckets, so a whole-session 1% low needs no per-frame storage.
struct FrameTimeHistogram {
    static let bucketMS = 0.1
    /// Up to 2 s per frame; anything longer lands in the last bucket.
    private(set) var counts = [Int](repeating: 0, count: 20_000)
    private(set) var total = 0

    mutating func add(_ ms: Double) {
        counts[min(counts.count - 1, max(0, Int(ms / Self.bucketMS)))] += 1
        total += 1
    }

    /// Average FPS of the slowest 1% of frames (at least one): the same definition as the 10-second 1% low.
    var onePercentLowFPS: Double? {
        guard total >= 20 else { return nil }
        var remaining = max(1, total / 100), frames = 0, sumMS = 0.0
        for bucket in stride(from: counts.count - 1, through: 0, by: -1) where counts[bucket] > 0 {
            let taken = min(counts[bucket], remaining)
            sumMS += Double(taken) * (Double(bucket) + 0.5) * Self.bucketMS
            frames += taken
            remaining -= taken
            if remaining == 0 { break }
        }
        return 1000 / (sumMS / Double(frames))
    }
}
