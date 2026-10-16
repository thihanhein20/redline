import Foundation

/// One snapshot of everything Redline measures. `nil` means "not available" (yet, or on this Mac).
struct SystemStats {
    // Frames
    var fps: Double?
    var pacing: FramePacing?
    /// GPU time per frame (ms) for games launched with `redline run`, from Apple's HUD output.
    var gpuFrameMS: Double?
    var displayHz: Int?

    // Whole Mac
    var cpuUsage: Double?
    var gpuUsage: Double?
    var memoryUsedGB: Double?
    var memoryTotalGB: Double = 0
    var memoryPressure: MemoryPressure?
    var swapUsedGB: Double?

    // The game being measured
    var game: GameProcess?

    // Chip
    var cpuTemperature: Double?
    var gpuTemperature: Double?
    var socTemperature: Double?
    var power: ChipPower?
    var battery: BatteryStatus?
    var thermalState: ProcessInfo.ThermalState = .nominal

    /// Set on the reading right after the tester pressed the marker hotkey.
    var marker: Int?
}
