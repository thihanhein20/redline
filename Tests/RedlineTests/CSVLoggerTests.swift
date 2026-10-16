import Foundation
import Testing
@testable import Redline

struct CSVLoggerTests {
    private let midnight = Date(timeIntervalSince1970: 0)

    @Test func rowHasOneCellPerHeaderColumn() {
        let stats = SystemStats(fps: 59.94, cpuUsage: 12.34, memoryUsedGB: 8.5, memoryTotalGB: 16, marker: 2)
        let cells = CSVLogger.row(for: stats, at: midnight).split(separator: ",", omittingEmptySubsequences: false)
        #expect(cells.count == CSVLogger.header.split(separator: ",").count)
        #expect(cells.first == "1970-01-01T00:00:00Z")
        #expect(cells[1] == "59.9")
        #expect(cells.last == "2")
    }

    @Test func missingReadingsAreEmptyCells() {
        let row = CSVLogger.row(for: SystemStats(), at: midnight)
        #expect(row.hasPrefix("1970-01-01T00:00:00Z,,"))
    }

    @Test func commasInGameNamesDontAddColumns() {
        var stats = SystemStats()
        stats.game = GameProcess(processID: 1, name: "Hello, World", cpuPercent: nil, memoryMB: 1)
        let cells = CSVLogger.row(for: stats, at: midnight).split(separator: ",", omittingEmptySubsequences: false)
        #expect(cells.count == CSVLogger.header.split(separator: ",").count)
    }
}
