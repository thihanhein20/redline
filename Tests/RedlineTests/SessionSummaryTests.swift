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
        #expect(summary.throttledSeconds == 1)
        #expect(summary.markers == 1)
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
