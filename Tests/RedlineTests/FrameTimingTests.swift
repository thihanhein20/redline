import Testing
@testable import Redline

struct FrameTimingTests {
    @Test func onePercentLowIsTheSlowestFramesAsFPS() {
        // 99 smooth frames at 60 FPS and one 50 ms hitch: the 1% low is 20 FPS.
        let frames = Array(repeating: 1000.0 / 60, count: 99) + [50]
        #expect(FrameTimingService.onePercentLow(frames) == 20)
    }

    @Test func onePercentLowNeedsEnoughFrames() {
        #expect(FrameTimingService.onePercentLow([16.7, 16.7]) == nil)
    }

    @Test func stutterIsMoreThanTwiceTheTypicalFrame() {
        #expect(FrameTimingService.isStutter(40, median: 16.7))
        #expect(!FrameTimingService.isStutter(30, median: 16.7))
        #expect(!FrameTimingService.isStutter(100, median: nil))
    }
}
