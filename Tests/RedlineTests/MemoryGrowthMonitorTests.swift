import Testing
@testable import Redline

struct MemoryGrowthMonitorTests {
    /// Feeds one reading per second and records the status after each.
    private func run(_ readings: [Double]) -> (monitor: MemoryGrowthMonitor, statuses: [MemoryGrowthStatus]) {
        var monitor = MemoryGrowthMonitor()
        var statuses: [MemoryGrowthStatus] = []
        for reading in readings {
            monitor.add(reading)
            statuses.append(monitor.status)
        }
        return (monitor, statuses)
    }

    @Test func aSingleLoadingJumpIsGrowthButNeverALeak() {
        // Flat 800 MB, a 300 MB jump two minutes in (loading a level), then flat for three more minutes.
        let readings = Array(repeating: 800.0, count: 120) + Array(repeating: 1100, count: 180)
        let (monitor, statuses) = run(readings)
        #expect(statuses.contains(.growing))
        #expect(!statuses.contains(.possibleLeak))
        #expect(monitor.status == .stable)  // once the jump has left the window
    }

    @Test func steadyGrowthBecomesAPossibleLeakAfterThreeMinutes() {
        // +0.5 MB every second (30 MB/min) for five minutes.
        let (_, statuses) = run((0..<300).map { 800 + Double($0) * 0.5 })
        let firstLeak = statuses.firstIndex(of: .possibleLeak).map { $0 + 1 }
        // Warm-up (10 s) + history (30 s) + 180 s sustained.
        #expect(firstLeak == MemoryGrowthMonitor.warmUpSeconds + 30 - 1 + MemoryGrowthMonitor.leakAfterSeconds)
        #expect(statuses.last == .possibleLeak)
    }

    @Test func growthThatStopsClearsTheWarning() {
        // Grows for two minutes (an action repeating), then the action stops and memory holds steady.
        let growing = (0..<120).map { 800 + Double($0) * 0.5 }
        let (monitor, statuses) = run(growing + Array(repeating: growing.last!, count: 120))
        #expect(statuses.contains(.growing))
        #expect(!statuses.contains(.possibleLeak))
        #expect(monitor.status == .stable)
        #expect(monitor.sustainedSeconds == 0)
    }

    @Test func warmUpIsIgnored() {
        // Memory triples during the first 10 seconds (start-up load), then stays flat.
        let readings = (0..<10).map { 300 + Double($0) * 60 } + Array(repeating: 900, count: 60)
        let (_, statuses) = run(readings)
        #expect(!statuses.contains(.growing))
    }
}
