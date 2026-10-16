import Testing
@testable import Redline

struct HUDFrameReportTests {
    @Test func parsesIntervalAndGPUTimePairs() throws {
        let line = "2026-10-11 10:00:00.000 Game[1:2] metal-HUD: 186,136.27,176.30,16.53,2.21,16.82,2.08,16.61,2.13"
        let report = try #require(HUDFrameReport.parse(line))
        #expect(report.frameIntervalsMS == [16.53, 16.82, 16.61])
        #expect(report.gpuTimesMS == [2.21, 2.08, 2.13])
        #expect(report.medianGPUTimeMS == 2.13)
    }

    @Test func rejectsOtherLinesAndPrivateLogLines() {
        #expect(HUDFrameReport.parse("Loading scene…") == nil)
        #expect(HUDFrameReport.parse("metal-HUD: 35,8.11,28.16<private>") == nil)
    }
}
