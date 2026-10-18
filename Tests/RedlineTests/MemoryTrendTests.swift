import Testing
@testable import Redline

struct MemoryTrendTests {
    @Test func steadyGrowthIsReportedPerMinute() {
        // +0.5 MB every second for a minute = 30 MB/min.
        let readings = (0..<60).map { 800 + Double($0) * 0.5 }
        #expect(MemoryTrend.growthPerMinute(readings) == 30)
    }

    @Test func flatMemoryHasNoGrowth() {
        #expect(MemoryTrend.growthPerMinute(Array(repeating: 800, count: 60)) == 0)
    }

    @Test func needsHalfAMinuteOfReadings() {
        #expect(MemoryTrend.growthPerMinute([1, 2, 3]) == nil)
    }
}
