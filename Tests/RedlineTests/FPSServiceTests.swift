import Testing
@testable import Redline

struct FPSServiceTests {
    @Test func fpsIsFramesPerElapsedSecond() {
        #expect(FPSService.fps(frames: 30, elapsed: .milliseconds(500)) == 60)
    }

    @Test func fpsIsNilWhenNoTimePassed() {
        #expect(FPSService.fps(frames: 10, elapsed: .zero) == nil)
    }
}
