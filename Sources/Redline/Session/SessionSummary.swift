import Foundation

/// Totals for one play session: what a tester wants to know after closing the game.
struct SessionSummary {
    var game: String?
    var startedAt = Date()
    var seconds = 0
    var minFPS: Double?
    var worstOnePercentLow: Double?
    var stutters = 0
    var maxCPUTemperature: Double?
    var maxGPUTemperature: Double?
    var peakPowerWatts: Double?
    var peakGameMemoryMB: Double?
    var fastestMemoryGrowthMBPerMinute: Double?
    var peakSwapGB: Double?
    var swappingSeconds = 0
    var peakGameGPUPercent: Double?
    var peakGameCPUPowerWatts: Double?
    var throttledSeconds = 0
    var markers = 0
    private var fpsTotal = 0.0
    private var fpsSamples = 0

    var averageFPS: Double? {
        fpsSamples > 0 ? fpsTotal / Double(fpsSamples) : nil
    }

    /// Adds one second of readings.
    mutating func add(_ stats: SystemStats) {
        seconds += 1
        game = stats.game?.name ?? game
        if let fps = stats.fps {
            fpsTotal += fps
            fpsSamples += 1
            minFPS = Swift.min(minFPS ?? fps, fps)
        }
        if let low = stats.pacing?.onePercentLowFPS { worstOnePercentLow = Swift.min(worstOnePercentLow ?? low, low) }
        stutters = Swift.max(stutters, stats.pacing?.stutters ?? 0)
        maxCPUTemperature = Self.max(maxCPUTemperature, stats.cpuTemperature ?? stats.socTemperature)
        maxGPUTemperature = Self.max(maxGPUTemperature, stats.gpuTemperature)
        peakPowerWatts = Self.max(peakPowerWatts, stats.power?.totalWatts)
        peakGameMemoryMB = Self.max(peakGameMemoryMB, stats.game?.memoryMB)
        fastestMemoryGrowthMBPerMinute = Self.max(fastestMemoryGrowthMBPerMinute, stats.game?.memoryGrowthMBPerMinute)
        peakSwapGB = Self.max(peakSwapGB, stats.swapUsedGB)
        if (stats.swapInMBps ?? 0) + (stats.swapOutMBps ?? 0) >= 1 { swappingSeconds += 1 }
        peakGameGPUPercent = Self.max(peakGameGPUPercent, stats.game?.gpuPercent)
        peakGameCPUPowerWatts = Self.max(peakGameCPUPowerWatts, stats.game?.cpuPowerWatts)
        if stats.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue { throttledSeconds += 1 }
        if stats.marker != nil { markers += 1 }
    }

    private static func max(_ current: Double?, _ new: Double?) -> Double? {
        guard let new else { return current }
        return Swift.max(current ?? new, new)
    }
}
