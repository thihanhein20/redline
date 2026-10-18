import Observation

/// Measures the game itself: CPU, GPU share, memory and its trend. History restarts when the game changes.
@MainActor
@Observable
final class GameTracker {
    /// The game's memory over the last minute, for the leak check and the memory graph.
    private(set) var memoryHistory = History(capacity: 60)

    @ObservationIgnored private let process = ProcessService()
    @ObservationIgnored private let gpu = GameGPUService()
    @ObservationIgnored private var owner: Int32?
    @ObservationIgnored private var secondsSinceStart = 0
    /// Games balloon in memory while loading; tracking the trend from the start would look like a leak.
    private static let warmUpSeconds = 10

    func sample(processID: Int32?, metalMemoryMB: Double?) -> GameProcess? {
        guard let processID, var game = process.stats(for: processID) else {
            memoryHistory.append(nil)
            return nil
        }
        if owner != processID {
            owner = processID
            secondsSinceStart = 0
            memoryHistory = History(capacity: memoryHistory.capacity)
        }
        secondsSinceStart += 1
        memoryHistory.append(secondsSinceStart > Self.warmUpSeconds ? game.memoryMB : nil)
        game.gpuPercent = gpu.usage(of: processID)
        game.metalMemoryMB = metalMemoryMB
        game.memoryGrowthMBPerMinute = MemoryTrend.growthPerMinute(memoryHistory.values.compactMap { $0 })
        return game
    }
}
