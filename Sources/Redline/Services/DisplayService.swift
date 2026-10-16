import AppKit

/// Refresh rate of the main display: the FPS ceiling for windowed games.
@MainActor
struct DisplayService {
    func refreshRate() -> Int? {
        NSScreen.main.map { $0.maximumFramesPerSecond }
    }
}
