import Foundation
import Testing
@testable import Redline

/// Fixes from the code review: game selection, session splitting, stutter events, session 1% low, HUD restore.
struct ReviewFixTests {
    private let now = Date()

    @Test func followsTheFrontmostReportingApp() {
        let reported: [Int32: Date] = [10: now, 20: now.addingTimeInterval(-1)]
        #expect(HUDLogFPSService.choose(reported, frontmost: 20) == 20)  // in front, even if it reported earlier
    }

    @Test func otherwiseFollowsTheAppThatReportedLast() {
        let reported: [Int32: Date] = [10: now, 20: now.addingTimeInterval(-1)]
        #expect(HUDLogFPSService.choose(reported, frontmost: 99) == 10)  // the frontmost app isn't reporting FPS
        #expect(HUDLogFPSService.choose([:], frontmost: 10) == nil)
    }

    @MainActor @Test func aDifferentGameStartsANewSession() {
        let recorder = SessionRecorder()
        func play(_ name: String, id: Int32, seconds: Int) {
            for _ in 0..<seconds {
                var stats = SystemStats(fps: 60)
                stats.game = GameProcess(processID: id, name: name, memoryMB: 500)
                recorder.record(stats)
            }
        }
        play("First", id: 1, seconds: 10)
        play("Second", id: 2, seconds: 10)
        #expect(recorder.last?.game == "First")   // ended when the game changed
        #expect(recorder.last?.seconds == 10)
        recorder.finish()
        #expect(recorder.last?.game == "Second")
        #expect(recorder.last?.seconds == 10)
    }

    @Test func aRunOfSlowFramesIsOneStutter() {
        var stuttering = false
        // Two hitches: one 3-frame run, one single slow frame.
        let frames = [16.7, 50, 50, 50, 16.7, 16.7, 45, 16.7]
        #expect(FrameTimingService.stutterEvents(in: frames, median: 16.7, alreadyStuttering: &stuttering) == 2)
    }

    @Test func aHitchSpanningTwoSamplesCountsOnce() {
        var stuttering = false
        _ = FrameTimingService.stutterEvents(in: [16.7, 50], median: 16.7, alreadyStuttering: &stuttering)
        #expect(FrameTimingService.stutterEvents(in: [50, 16.7], median: 16.7, alreadyStuttering: &stuttering) == 0)
    }

    @Test func sessionOnePercentLowCoversEveryFrame() throws {
        var histogram = FrameTimeHistogram()
        for _ in 0..<99 { histogram.add(1000.0 / 60) }
        histogram.add(50)
        // Same definition as the 10-second figure: average of the slowest 1% → one 50 ms frame ≈ 20 FPS.
        let low = try #require(histogram.onePercentLowFPS)
        #expect(abs(low - 20) < 0.1)
    }

    @Test func hudSettingsAreRestoredToTheUsersValues() {
        let arguments = MetalHUDService.restoreArguments(previous: ["MTL_HUD_ENABLED": "1", "MTL_HUD_HIDDEN": ""])
        #expect(arguments == [["setenv", "MTL_HUD_ENABLED", "1"], ["unsetenv", "MTL_HUD_HIDDEN"]])
    }
}
