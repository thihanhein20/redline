import Testing
@testable import Redline

struct HUDLogEntryTests {
    private func line(frames: Int, at time: String) -> String {
        #"{"processID":23373,"timestamp":"2026-10-10 12:09:\#(time)+1100","eventMessage":"metal-HUD: \#(frames),8.11,28.16<private>"}"#
    }

    @Test func parsesFrameCountAndTimestamp() throws {
        let entry = try #require(HUDLogEntry.parse(line(frames: 35, at: "59.265541")))
        #expect(entry.processID == 23373)
        #expect(entry.totalFrames == 35)
    }

    @Test func ignoresOtherLogLines() {
        #expect(HUDLogEntry.parse("Filtering the log data using ...") == nil)
        #expect(HUDLogEntry.parse(#"{"processID":1,"timestamp":"2026-10-10 12:09:59.000000+1100","eventMessage":"hello"}"#) == nil)
    }

    @Test func fpsIsFramesBetweenEntriesPerSecond() throws {
        let old = try #require(HUDLogEntry.parse(line(frames: 35, at: "59.000000")))
        let new = try #require(HUDLogEntry.parse(line(frames: 65, at: "59.500000")))
        #expect(HUDLogEntry.fps(from: old, to: new) == 60)
    }
}
