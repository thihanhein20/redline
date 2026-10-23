/// Growth rate of a series of once-a-second readings, for spotting memory leaks.
enum MemoryTrend {
    /// Least-squares slope in units per minute. Needs at least 30 seconds of readings to mean anything.
    static func growthPerMinute(_ values: [Double]) -> Double? {
        guard values.count >= 30 else { return nil }
        let n = Double(values.count)
        let meanX = (n - 1) / 2, meanY = values.reduce(0, +) / n
        var covariance = 0.0, variance = 0.0
        for (index, value) in values.enumerated() {
            let dx = Double(index) - meanX
            covariance += dx * (value - meanY)
            variance += dx * dx
        }
        return covariance / variance * 60
    }
}
