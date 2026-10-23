import Testing
@testable import Redline

struct StatFormatTests {
    @Test func gameMemoryShowsNoticeableGrowthOnly() {
        var game = GameProcess(processID: 1, name: "G", memoryMB: 1240)
        #expect(StatFormat.gameMemory(game) == "1240 MB")
        game.memoryGrowthMBPerMinute = 0.4
        #expect(StatFormat.gameMemory(game) == "1240 MB")
        game.memoryGrowthMBPerMinute = -12
        #expect(StatFormat.gameMemory(game) == "1240 MB ↓12/m")
    }

    @Test func diskIsHiddenWhenIdle() {
        #expect(StatFormat.disk(read: 0, write: 0.05) == nil)
        #expect(StatFormat.disk(read: 12.4, write: 3) == "R 12 W 3 MB/s")
    }

    @Test func swapShowsActivityOnlyWhileSwapping() {
        #expect(StatFormat.swap(usedGB: 2.4, activityMBps: 0) == "2.4 GB")
        #expect(StatFormat.swap(usedGB: 2.4, activityMBps: 5.2) == "2.4 GB ⇅5MB/s")
    }
}
