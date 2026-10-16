import Foundation

/// Turns raw readings into short overlay strings. "--" means no reading yet.
enum StatFormat {
    static let placeholder = "--"
    static let hotCelsius = 90.0

    /// "60  16.7ms": frames per second and average frame time.
    static func fps(_ value: Double?) -> String {
        guard let value else { return placeholder }
        guard value > 0 else { return "0" }
        return String(format: "%.0f  %.1fms", value, 1000 / value)
    }

    static func whole(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    static func watts(_ value: Double) -> String {
        String(format: "%.1f W", value)
    }

    static func gigahertz(_ mhz: Double) -> String {
        String(format: "%.2f GHz", mhz / 1000)
    }

    /// "45% · 812 MB": the game's own CPU (100% = one core) and memory.
    static func game(_ game: GameProcess) -> String {
        "\(percent(game.cpuPercent)) · \(String(format: "%.0f MB", game.memoryMB))"
    }

    /// "78% −12.1 W" on battery, "100% AC" when plugged in.
    static func battery(_ battery: BatteryStatus) -> String {
        guard battery.onBattery, let drain = battery.drainWatts else { return "\(battery.percent)% AC" }
        return "\(battery.percent)% " + String(format: "−%.1f W", drain)
    }

    static func percent(_ value: Double?) -> String {
        value.map { String(format: "%.0f%%", $0) } ?? placeholder
    }

    static func celsius(_ value: Double?) -> String {
        value.map { String(format: "%.0f°C", $0) } ?? placeholder
    }

    static func memory(used: Double?, total: Double) -> String {
        used.map { String(format: "%.1f/%.0f GB", $0, total) } ?? placeholder
    }

    static func isHot(_ celsius: Double?) -> Bool {
        (celsius ?? 0) >= hotCelsius
    }

    static func thermal(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: "OK"
        case .fair: "FAIR"
        case .serious: "HOT"
        case .critical: "CRITICAL"
        @unknown default: placeholder
        }
    }
}
