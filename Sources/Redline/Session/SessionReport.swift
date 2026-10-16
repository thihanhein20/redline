import Foundation

/// Formats a session summary as a few readable lines (Settings window and the end of a Terminal run).
enum SessionReport {
    static func lines(for summary: SessionSummary) -> [(label: String, value: String)] {
        var lines: [(String, String)] = [
            ("Game", summary.game ?? "Unknown"),
            ("Duration", duration(summary.seconds)),
            ("Average FPS", number(summary.averageFPS)),
            ("Lowest FPS", number(summary.minFPS)),
        ]
        if let low = summary.worstOnePercentLow { lines.append(("Worst 1% low", number(low))) }
        if summary.stutters > 0 { lines.append(("Stutters", "\(summary.stutters)")) }
        lines += [
            ("Max CPU temp", celsius(summary.maxCPUTemperature)),
            ("Max GPU temp", celsius(summary.maxGPUTemperature)),
            ("Peak power", summary.peakPowerWatts.map { String(format: "%.1f W", $0) } ?? StatFormat.placeholder),
            ("Peak game memory", summary.peakGameMemoryMB.map { String(format: "%.0f MB", $0) } ?? StatFormat.placeholder),
            ("Time throttled", duration(summary.throttledSeconds)),
        ]
        if summary.markers > 0 { lines.append(("Markers", "\(summary.markers)")) }
        return lines
    }

    static func text(for summary: SessionSummary) -> String {
        let lines = lines(for: summary)
        let width = lines.map(\.label.count).max() ?? 0
        let body = lines.map { $0.label.padding(toLength: width, withPad: " ", startingAt: 0) + "  " + $0.value }
        return (["── Redline session ──"] + body).joined(separator: "\n")
    }

    static func duration(_ seconds: Int) -> String {
        seconds >= 60 ? "\(seconds / 60)m \(seconds % 60)s" : "\(seconds)s"
    }

    private static func number(_ value: Double?) -> String {
        value.map { String(format: "%.0f", $0) } ?? StatFormat.placeholder
    }

    private static func celsius(_ value: Double?) -> String {
        value.map { String(format: "%.0f°C", $0) } ?? StatFormat.placeholder
    }
}
