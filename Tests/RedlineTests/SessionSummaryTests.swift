import Foundation
import Testing
@testable import Redline

struct SessionSummaryTests {
    @Test func tracksAveragesAndPeaks() {
        var summary = SessionSummary()
        var hot = SystemStats(fps: 40, cpuTemperature: 80)
        hot.thermalState = .serious
        hot.marker = 1
        for stats in [SystemStats(fps: 60, cpuTemperature: 70), hot] { summary.add(stats) }
        #expect(summary.seconds == 2)
        #expect(summary.averageFPS == 50)
        #expect(summary.minFPS == 40)
        #expect(summary.maxCPUTemperature == 80)
        #expect(summary.seriousThermalSeconds == 1)
        #expect(summary.markers == 1)
    }

    @Test func peakAndFinalGrowthAreKeptApart() {
        var summary = SessionSummary()
        var stats = SystemStats(fps: 60)
        for growth in [5.0, 40, 12] {
            stats.game = GameProcess(processID: 1, name: "G", memoryMB: 900, memoryGrowthMBPerMinute: growth, memoryStatus: .growing)
            summary.add(stats)
        }
        #expect(summary.peakMemoryGrowthMBPerMinute == 40)
        #expect(summary.peakMemoryGrowthAt == 2)
        #expect(summary.finalMemoryGrowthMBPerMinute == 12)
        #expect(summary.worstMemoryStatus == .growing)
        let text = SessionReport.text(for: summary)
        #expect(text.contains("Growth detected"))
        #expect(!text.contains("Possible leak"))
    }

    @Test func settingsShowOnlyHighlights() {
        var summary = SessionSummary()
        summary.add(SystemStats(fps: 60))
        let labels = SessionReport.highlights(for: summary).map(\.label)
        #expect(labels == ["Game", "Duration", "Average FPS", "Lowest FPS", "Max temp", "Memory"])
    }

    @Test func reportListsKeyNumbers() {
        var summary = SessionSummary()
        summary.add(SystemStats(fps: 60))
        let text = SessionReport.text(for: summary)
        #expect(text.contains("Average FPS"))
        #expect(text.contains("60"))
        #expect(!text.contains("Stutters"))  // only shown when there were some
    }
}
