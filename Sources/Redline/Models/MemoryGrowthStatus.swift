/// What the game's memory trend says. Growth alone isn't proof of a leak: loading, streaming and caches grow too.
enum MemoryGrowthStatus: String {
    case stable
    /// Growing faster than the threshold right now.
    case growing
    /// Growth sustained for several minutes: worth investigating with a memory profiler.
    case possibleLeak = "possible_leak"

    var label: String {
        switch self {
        case .stable: "Stable"
        case .growing: "Growth detected"
        case .possibleLeak: "Possible leak"
        }
    }
}
