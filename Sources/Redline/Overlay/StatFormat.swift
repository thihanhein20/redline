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

    /// "1240 MB ↑12/m": footprint, plus growth per minute when it's noticeable.
    static func gameMemory(_ game: GameProcess) -> String {
        let size = String(format: "%.0f MB", game.memoryMB)
        guard let growth = game.memoryGrowthMBPerMinute, abs(growth) >= 1 else { return size }
        return size + String(format: " %@%.0f/m", growth > 0 ? "↑" : "↓", abs(growth))
    }

    /// "R 12 W 3 MB/s", or nil when the game isn't touching the disk.
    static func disk(read: Double?, write: Double?) -> String? {
        let r = read ?? 0, w = write ?? 0
        guard r >= 0.1 || w >= 0.1 else { return nil }
        return String(format: "R %.0f W %.0f MB/s", r, w)
    }

    /// "2.4 GB", plus "⇅5 MB/s" while macOS is actively swapping.
    static func swap(usedGB: Double, activityMBps: Double) -> String {
        let size = String(format: "%.1f GB", usedGB)
        return activityMBps >= 0.1 ? size + String(format: " ⇅%.0fMB/s", activityMBps) : size
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
