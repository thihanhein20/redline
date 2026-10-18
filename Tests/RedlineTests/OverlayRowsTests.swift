import Testing
@testable import Redline

struct OverlayRowsTests {
    private var everything: SystemStats {
        var stats = SystemStats(fps: 60, displayHz: 60, cpuUsage: 20, gpuUsage: 30, memoryUsedGB: 8, memoryTotalGB: 16)
        stats.pacing = FramePacing(onePercentLowFPS: 48, stutters: 2, frameTimesMS: [16.7, 16.7])
        stats.gpuFrameMS = 2.1
        stats.memoryPressure = .warning
        stats.memoryBreakdown = MemoryBreakdown(appGB: 5, wiredGB: 2, compressedGB: 1, cachedGB: 3)
        stats.swapUsedGB = 1.5
        stats.swapInMBps = 4
        stats.gpuMemoryMB = 330
        stats.game = GameProcess(processID: 1, name: "Game", cpuPercent: 45, gpuPercent: 30, memoryMB: 812,
                                 memoryGrowthMBPerMinute: 25, metalMemoryMB: 285, cpuPowerWatts: 4.4,
                                 diskReadMBps: 12, diskWriteMBps: 0, threads: 42)
        stats.cpuTemperature = 62
        stats.gpuTemperature = 95
        stats.power = ChipPower(cpuWatts: 8, gpuWatts: 3, totalWatts: 12.3, eCoreMHz: 2000, pCoreMHz: 3504, gpuMHz: 1236)
        stats.battery = BatteryStatus(percent: 78, isCharging: false, onBattery: true, drainWatts: 12.1)
        return stats
    }

    private func labels(_ items: [OverlayItem]) -> [String] { items.compactMap(\.label) }

    @Test func compactShowsTheEssentials() {
        #expect(labels(OverlayRows.items(for: everything, detail: .compact)) == ["FPS", "1% LOW", "CPU", "GPU", "RAM", "TEMP", "THERM"])
    }

    @Test func fullShowsEverything() {
        let items = OverlayRows.items(for: everything, detail: .full)
        #expect(labels(items) == ["FPS", "1% LOW", "STUTTERS", "GPU TIME", "DISPLAY", "CPU", "GPU",
                                  "GAME", "GAME CPU", "GAME GPU", "GAME MEM", "GAME VRAM", "GAME CPU PWR", "GAME DISK", "THREADS",
                                  "RAM", "SWAP", "GPU MEM",
                                  "CPU TEMP", "GPU TEMP", "POWER", "CPU CLK", "GPU CLK", "BATTERY", "THERM"])
        #expect(items.contains(.frameTimeGraph))
        #expect(items.contains(.gameMemoryGraph))
        #expect(items.contains(.memoryBar(MemoryBreakdown(appGB: 5, wiredGB: 2, compressedGB: 1, cachedGB: 3))))
    }

    @Test func readingsMissingOnThisMacAreLeftOut() {
        let items = OverlayRows.items(for: SystemStats(fps: 60, socTemperature: 50), detail: .full)
        #expect(labels(items) == ["FPS", "CPU", "GPU", "RAM", "TEMP", "THERM"])
    }

    @Test func warningsAreHighlighted() {
        let items = OverlayRows.items(for: everything, detail: .full)
        #expect(items.contains(.stat(label: "GPU TEMP", value: "95°C", emphasis: .hot)))
        #expect(items.contains(.stat(label: "RAM", value: "8.0/16 GB", emphasis: .warning)))
        #expect(items.contains(.stat(label: "GAME MEM", value: "812 MB ↑25/m", emphasis: .warning)))  // possible leak
        #expect(items.contains(.stat(label: "SWAP", value: "1.5 GB ⇅4MB/s", emphasis: .hot)))      // actively swapping
    }

    @Test func markerShowsFirst() {
        #expect(OverlayRows.items(for: everything, detail: .compact, marker: 3).first == .marker(3))
    }
}
