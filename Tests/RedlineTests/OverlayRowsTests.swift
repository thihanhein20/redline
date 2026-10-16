import Testing
@testable import Redline

struct OverlayRowsTests {
    private var everything: SystemStats {
        var stats = SystemStats(fps: 60, displayHz: 60, cpuUsage: 20, gpuUsage: 30, memoryUsedGB: 8, memoryTotalGB: 16)
        stats.pacing = FramePacing(onePercentLowFPS: 48, stutters: 2, frameTimesMS: [16.7, 16.7])
        stats.gpuFrameMS = 2.1
        stats.memoryPressure = .warning
        stats.swapUsedGB = 1.5
        stats.game = GameProcess(processID: 1, name: "Game", cpuPercent: 45, memoryMB: 812)
        stats.cpuTemperature = 62
        stats.gpuTemperature = 95
        stats.power = ChipPower(cpuWatts: 8, gpuWatts: 3, totalWatts: 12.3, eCoreMHz: 2000, pCoreMHz: 3504, gpuMHz: 1236)
        stats.battery = BatteryStatus(percent: 78, isCharging: false, onBattery: true, drainWatts: 12.1)
        return stats
    }

    private func labels(_ items: [OverlayItem]) -> [String] { items.compactMap(\.label) }

    @Test func compactShowsTheEssentials() {
        #expect(labels(OverlayRows.items(for: everything, detail: .compact)) == ["FPS", "1% LOW", "CPU", "GPU", "TEMP", "THERM"])
    }

    @Test func fullShowsEverything() {
        let items = OverlayRows.items(for: everything, detail: .full)
        #expect(labels(items) == ["FPS", "1% LOW", "STUTTERS", "GPU TIME", "DISPLAY", "CPU", "GPU", "GAME", "RAM", "SWAP",
                                  "CPU TEMP", "GPU TEMP", "POWER", "CPU CLK", "GPU CLK", "BATTERY", "THERM"])
        #expect(items.contains(.frameTimeGraph))
    }

    @Test func readingsMissingOnThisMacAreLeftOut() {
        let items = OverlayRows.items(for: SystemStats(fps: 60, socTemperature: 50), detail: .full)
        #expect(labels(items) == ["FPS", "CPU", "GPU", "RAM", "TEMP", "THERM"])
    }

    @Test func warningsAreHighlighted() {
        let items = OverlayRows.items(for: everything, detail: .full)
        #expect(items.contains(.stat(label: "GPU TEMP", value: "95°C", emphasis: .hot)))
        #expect(items.contains(.stat(label: "RAM", value: "8.0/16 GB", emphasis: .warning)))
    }

    @Test func markerShowsFirst() {
        #expect(OverlayRows.items(for: everything, detail: .compact, marker: 3).first == .marker(3))
    }
}
