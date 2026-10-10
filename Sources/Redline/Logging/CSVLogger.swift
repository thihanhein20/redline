import Foundation

/// Writes one CSV row per stats update to stdout. Redirect to keep a run: `redline run Game.app > run.csv`
struct CSVLogger {
    static let header = "timestamp,fps,cpu_pct,gpu_pct,ram_gb,soc_temp_c,thermal_state"

    func start() {
        write(Self.header)
    }

    func log(_ stats: SystemStats, at date: Date = .now) {
        write(Self.row(for: stats, at: date))
    }

    static func row(for stats: SystemStats, at date: Date) -> String {
        [
            date.formatted(.iso8601),
            number(stats.fps),
            number(stats.cpuUsage),
            number(stats.gpuUsage),
            number(stats.memoryUsedGB, digits: 2),
            number(stats.socTemperature),
            StatFormat.thermal(stats.thermalState),
        ].joined(separator: ",")
    }

    /// Empty cell when there's no reading, so spreadsheets treat it as missing rather than zero.
    private static func number(_ value: Double?, digits: Int = 1) -> String {
        value.map { String(format: "%.\(digits)f", $0) } ?? ""
    }

    private func write(_ line: String) {
        print(line)
        fflush(stdout)
    }
}
