import Foundation
import Testing
@testable import Redline

struct CSVLoggerTests {
    @Test func rowHasOneCellPerHeaderColumnAndBlanksForMissingValues() {
        let stats = SystemStats(fps: 59.94, cpuUsage: 12.34, memoryUsedGB: 8.5, memoryTotalGB: 16)
        let row = CSVLogger.row(for: stats, at: Date(timeIntervalSince1970: 0))
        #expect(row == "1970-01-01T00:00:00Z,59.9,12.3,,8.50,,OK")
        #expect(row.split(separator: ",", omittingEmptySubsequences: false).count
                == CSVLogger.header.split(separator: ",").count)
    }
}
