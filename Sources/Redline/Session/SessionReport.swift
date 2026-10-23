import Foundation

/// Formats a session summary: every detail for the saved .txt and Terminal, highlights for settings.
enum SessionReport {
    /// The few numbers worth seeing at a glance.
    static func highlights(for summary: SessionSummary) -> [(label: String, value: String)] {
        let worstFPS = summary.worstOnePercentLow.map { ("Worst 1% low", number($0)) } ?? ("Lowest FPS", number(summary.minFPS))
        return [
            ("Game", summary.game ?? "Unknown"),
            ("Duration", duration(summary.seconds)),
            ("Average FPS", number(summary.averageFPS)),
            worstFPS,
            ("Max temp", celsius(summary.maxCPUTemperature)),
            ("Memory", summary.worstMemoryStatus.label),
        ]
    }

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
            ("Peak game GPU", summary.peakGameGPUPercent.map { StatFormat.percent($0) } ?? StatFormat.placeholder),
            ("Peak game CPU power", summary.peakGameCPUPowerWatts.map(StatFormat.watts) ?? StatFormat.placeholder),
            ("Peak swap", summary.peakSwapGB.map { String(format: "%.1f GB", $0) } ?? StatFormat.placeholder),
            ("Time swapping", duration(summary.swappingSeconds)),
            ("Time throttled", duration(summary.throttledSeconds)),
        ]
        lines += memoryLines(summary)
        if summary.markers > 0 { lines.append(("Markers", "\(summary.markers)")) }
        return lines
    }

    static func text(for summary: SessionSummary) -> String {
        let lines = lines(for: summary)
        let width = lines.map(\.label.count).max() ?? 0
        let body = lines.map { $0.label.padding(toLength: width, withPad: " ", startingAt: 0) + "  " + $0.value }
        return (["── Redline session ──"] + body).joined(separator: "\n")
    }

    /// Careful wording: growth is only called a possible leak when it lasted several minutes.
    private static func memoryLines(_ summary: SessionSummary) -> [(String, String)] {
        var lines = [("Memory", summary.worstMemoryStatus.label)]
        switch summary.worstMemoryStatus {
        case .possibleLeak:
            lines.append(("", "growth lasted \(duration(summary.longestSustainedGrowthSeconds)); check with a memory profiler"))
        case .growing:
            lines.append(("", "growth didn't last \(duration(MemoryGrowthMonitor.leakAfterSeconds)) (often loading or caching)"))
        case .stable:
            break
        }
        if let peak = summary.peakMemoryGrowthMBPerMinute, peak >= MemoryGrowthMonitor.thresholdMBPerMinute {
            let at = summary.peakMemoryGrowthAt.map { " at \(duration($0))" } ?? ""
            lines.append(("Peak memory growth", String(format: "%.0f MB/min", peak) + at))
            if let final = summary.finalMemoryGrowthMBPerMinute {
                lines.append(("Growth at end", String(format: "%.0f MB/min", final)))
            }
        }
        return lines
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
