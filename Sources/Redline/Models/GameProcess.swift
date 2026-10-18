/// The game Redline is measuring: its own use of the Mac, not the whole Mac's.
struct GameProcess {
    var processID: Int32
    var name: String
    /// Like Activity Monitor: 100% = one full core, so it can exceed 100%.
    var cpuPercent: Double?
    /// Share of the GPU's time spent on this game's work.
    var gpuPercent: Double?
    /// Memory footprint, as in Activity Monitor's Memory column.
    var memoryMB: Double
    /// How fast memory is growing over the last minute; steady growth usually means a leak.
    var memoryGrowthMBPerMinute: Double?
    /// GPU memory the game has allocated (games launched with `redline run`).
    var metalMemoryMB: Double?
    /// CPU energy only: macOS doesn't split GPU energy by app.
    var cpuPowerWatts: Double?
    var diskReadMBps: Double?
    var diskWriteMBps: Double?
    var threads: Int?
}
