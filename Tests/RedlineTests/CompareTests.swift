import Testing
@testable import Redline

struct CompareTests {
    private let before = """
        timestamp,fps,stutters,cpu_temp_c
        t,60,0,70
        t,40,2,80
        """
    private let after = """
        timestamp,fps,stutters,cpu_temp_c
        t,60,0,60
        t,60,1,65
        """

    @Test func readsColumnsByName() throws {
        let run = try #require(RunMetrics.parse(csv: before, name: "before"))
        let values = Dictionary(uniqueKeysWithValues: run.metrics.map { ($0.label, $0.value) })
        #expect(values["Average FPS"] == 50)
        #expect(values["Lowest FPS"] == 40)
        #expect(values["Stutters"] == 2)
        #expect(values["Max CPU temp"] == 80)
        #expect(values["GPU time / frame"] == .some(nil))  // column not in this log
    }

    @Test func judgesBetterOrWorsePerMetric() throws {
        let a = try #require(RunMetrics.parse(csv: before, name: "a")), b = try #require(RunMetrics.parse(csv: after, name: "b"))
        let report = CompareReport.text(a, b)
        #expect(report.contains("+20.0% better"))  // average FPS 50 → 60
        #expect(report.contains("-50.0% better"))  // stutters 2 → 1
        #expect(!report.contains("GPU time"))       // missing in both: row skipped
        #expect(!report.contains("Duration") || !report.split(separator: "\n")[1].contains("better"))
    }

    @Test func rejectsFilesThatArentRedlineLogs() {
        #expect(RunMetrics.parse(csv: "name,score\nx,1", name: "x") == nil)
    }
}
