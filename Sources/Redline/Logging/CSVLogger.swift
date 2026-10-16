import Foundation

/// Writes one CSV row per stats update to stdout. Redirect to keep a run: `redline run Game.app > run.csv`
struct CSVLogger {
    /// Column names and how each is read from a snapshot. Empty cell = no reading.
    static let columns: [(name: String, value: @Sendable (SystemStats) -> String)] = [
        ("fps", { number($0.fps) }),
        ("fps_1pct_low", { number($0.pacing?.onePercentLowFPS) }),
        ("stutters", { $0.pacing.map { "\($0.stutters)" } ?? "" }),
        ("gpu_frame_ms", { number($0.gpuFrameMS, digits: 2) }),
        ("display_hz", { $0.displayHz.map(String.init) ?? "" }),
        ("cpu_pct", { number($0.cpuUsage) }),
        ("gpu_pct", { number($0.gpuUsage) }),
        ("ram_gb", { number($0.memoryUsedGB, digits: 2) }),
        ("mem_pressure", { $0.memoryPressure?.label ?? "" }),
        ("swap_gb", { number($0.swapUsedGB, digits: 2) }),
        // Commas would break the CSV, so they're dropped from game names.
        ("game", { $0.game?.name.replacingOccurrences(of: ",", with: " ") ?? "" }),
        ("game_cpu_pct", { number($0.game?.cpuPercent) }),
        ("game_mem_mb", { number($0.game?.memoryMB, digits: 0) }),
        ("cpu_temp_c", { number($0.cpuTemperature) }),
        ("gpu_temp_c", { number($0.gpuTemperature) }),
        ("soc_temp_c", { number($0.socTemperature) }),
        ("power_w", { number($0.power?.totalWatts, digits: 2) }),
        ("cpu_power_w", { number($0.power?.cpuWatts, digits: 2) }),
        ("gpu_power_w", { number($0.power?.gpuWatts, digits: 2) }),
        ("ecpu_mhz", { number($0.power?.eCoreMHz, digits: 0) }),
        ("pcpu_mhz", { number($0.power?.pCoreMHz, digits: 0) }),
        ("gpu_mhz", { number($0.power?.gpuMHz, digits: 0) }),
        ("battery_pct", { $0.battery.map { "\($0.percent)" } ?? "" }),
        ("battery_drain_w", { number($0.battery?.drainWatts, digits: 2) }),
        ("on_battery", { $0.battery.map { $0.onBattery ? "1" : "0" } ?? "" }),
        ("thermal_state", { StatFormat.thermal($0.thermalState) }),
        ("marker", { $0.marker.map(String.init) ?? "" }),
    ]

    static let header = (["timestamp"] + columns.map(\.name)).joined(separator: ",")

    func start() {
        write(Self.header)
    }

    func log(_ stats: SystemStats, at date: Date = .now) {
        write(Self.row(for: stats, at: date))
    }

    static func row(for stats: SystemStats, at date: Date) -> String {
        ([date.formatted(.iso8601)] + columns.map { $0.value(stats) }).joined(separator: ",")
    }

    private static func number(_ value: Double?, digits: Int = 1) -> String {
        value.map { String(format: "%.\(digits)f", $0) } ?? ""
    }

    private func write(_ line: String) {
        print(line)
        fflush(stdout)
    }
}
