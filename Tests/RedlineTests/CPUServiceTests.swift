import Testing
@testable import Redline

struct CPUServiceTests {
    @Test func usageIsBusyShareOfElapsedTicks() {
        let old = CPUTicks(busy: 100, total: 400)
        let new = CPUTicks(busy: 150, total: 600)
        #expect(CPUService.usage(from: old, to: new) == 25)
    }

    @Test func usageIsNilWhenNoTimePassed() {
        let ticks = CPUTicks(busy: 100, total: 400)
        #expect(CPUService.usage(from: ticks, to: ticks) == nil)
    }
}
