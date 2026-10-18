/// Where the Mac's RAM is going, as in Activity Monitor's Memory tab.
struct MemoryBreakdown: Equatable {
    var appGB: Double
    var wiredGB: Double
    var compressedGB: Double
    /// File cache: macOS frees this whenever apps need the memory.
    var cachedGB: Double
}
