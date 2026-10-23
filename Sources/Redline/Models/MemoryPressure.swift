/// macOS memory pressure (Activity Monitor's green / yellow / red).
enum MemoryPressure: Int {
    case normal = 1
    case warning = 2
    case critical = 4

    var label: String {
        switch self {
        case .normal: "OK"
        case .warning: "WARN"
        case .critical: "CRIT"
        }
    }
}
