import Observation

/// Measures the game itself: CPU, GPU share, memory and its trend. History restarts when the game changes.
@MainActor
@Observable
final class GameTracker {
    private(set) var memory = MemoryGrowthMonitor()

    @ObservationIgnored private let process = ProcessService()
    @ObservationIgnored private let gpu = GameGPUService()
    @ObservationIgnored private var owner: Int32?

    /// The game's memory over the last minute, for the overlay's memory graph.
    var memoryHistory: History { memory.history }

    func sample(processID: Int32?, metalMemoryMB: Double?) -> GameProcess? {
        guard let processID, var game = process.stats(for: processID) else {
            memory.addGap()
            return nil
        }
        if owner != processID {
            owner = processID
            memory = MemoryGrowthMonitor()
        }
        memory.add(game.memoryMB)
        game.gpuPercent = gpu.usage(of: processID)
        game.metalMemoryMB = metalMemoryMB
        game.memoryGrowthMBPerMinute = memory.growthMBPerMinute
        game.memoryStatus = memory.status
        game.sustainedGrowthSeconds = memory.sustainedSeconds
        return game
    }
}
