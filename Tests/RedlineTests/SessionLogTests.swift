import Foundation
import Testing
@testable import Redline

struct SessionLogTests {
    private let folder = FileManager.default.temporaryDirectory.appendingPathComponent("redline-log-test-\(UUID().uuidString)")

    @Test func fileNameIsGameAndStartTimeWithoutSlashes() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 9, minute: 5, second: 7))!
        #expect(SessionLog.baseName(game: "Half/Life: 3", startedAt: date) == "Half-Life- 3_2026-10-16_09-05-07")
        #expect(SessionLog.baseName(game: nil, startedAt: date) == "Session_2026-10-16_09-05-07")
    }

    @Test func writesCSVRowsAndSummary() throws {
        let log = try #require(SessionLog(game: "Game", startedAt: Date(), folder: folder))
        log.append(SystemStats(fps: 60))
        log.append(SystemStats(fps: 58))
        var summary = SessionSummary()
        summary.add(SystemStats(fps: 60))
        log.finish(with: summary)

        let csv = try String(contentsOf: log.csvURL, encoding: .utf8).split(separator: "\n")
        #expect(csv.count == 3)
        #expect(csv.first.map(String.init) == CSVLogger.header)
        let text = try String(contentsOf: log.csvURL.deletingPathExtension().appendingPathExtension("txt"), encoding: .utf8)
        #expect(text.contains("Average FPS"))
    }

    @Test func discardDeletesTheFile() throws {
        let log = try #require(SessionLog(game: "Game", startedAt: Date(), folder: folder))
        log.discard()
        #expect(!FileManager.default.fileExists(atPath: log.csvURL.path))
    }
}
