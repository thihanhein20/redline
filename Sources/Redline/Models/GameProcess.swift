/// The game Redline is measuring: its own CPU and memory use, not the whole Mac's.
struct GameProcess {
    var processID: Int32
    var name: String
    /// Like Activity Monitor: 100% = one full core, so it can exceed 100%.
    var cpuPercent: Double?
    var memoryMB: Double
}
