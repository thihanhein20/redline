import Foundation

/// The key numbers of one Redline CSV log, for comparing runs. Columns are found by name,
/// so logs from older Redline versions (fewer columns) still compare.
struct RunMetrics {
    struct Metric {
        let label: String
        let value: Double?
        let unit: String
        /// `nil` for numbers that aren't better or worse, like duration.
        let higherIsBetter: Bool?
    }

    let name: String
    let metrics: [Metric]

    static func parse(csv: String, name: String) -> RunMetrics? {
        let lines = csv.split(whereSeparator: \.isNewline).map(String.init)
        guard let header = lines.first?.split(separator: ",", omittingEmptySubsequences: false).map(String.init),
              header.first == "timestamp" else { return nil }
        let rows = lines.dropFirst().map { $0.split(separator: ",", omittingEmptySubsequences: false).map(String.init) }

        func column(_ name: String) -> [Double] {
            guard let index = header.firstIndex(of: name) else { return [] }
            return rows.compactMap { index < $0.count ? Double($0[index]) : nil }
        }
        func average(_ values: [Double]) -> Double? { values.isEmpty ? nil : values.reduce(0, +) / Double(values.count) }

        let fps = column("fps")
        let cpuTemps = column("cpu_temp_c").isEmpty ? column("soc_temp_c") : column("cpu_temp_c")
        return RunMetrics(name: name, metrics: [
            Metric(label: "Duration", value: Double(fps.count), unit: "s", higherIsBetter: nil),
            Metric(label: "Average FPS", value: average(fps), unit: "", higherIsBetter: true),
            Metric(label: "Lowest FPS", value: fps.min(), unit: "", higherIsBetter: true),
            Metric(label: "Average 1% low", value: average(column("fps_1pct_low")), unit: "", higherIsBetter: true),
            Metric(label: "Stutters", value: column("stutters").max(), unit: "", higherIsBetter: false),
            Metric(label: "GPU time / frame", value: average(column("gpu_frame_ms")), unit: "ms", higherIsBetter: false),
            Metric(label: "Game CPU", value: average(column("game_cpu_pct")), unit: "%", higherIsBetter: false),
            Metric(label: "Peak game memory", value: column("game_mem_mb").max(), unit: "MB", higherIsBetter: false),
            Metric(label: "Max CPU temp", value: cpuTemps.max(), unit: "°C", higherIsBetter: false),
            Metric(label: "Max GPU temp", value: column("gpu_temp_c").max(), unit: "°C", higherIsBetter: false),
            Metric(label: "Average power", value: average(column("power_w")), unit: "W", higherIsBetter: false),
        ])
    }
}
