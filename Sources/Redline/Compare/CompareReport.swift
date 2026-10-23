import Foundation

/// Side-by-side table of two runs: `redline compare before.csv after.csv`.
enum CompareReport {
    static func text(_ before: RunMetrics, _ after: RunMetrics) -> String {
        var rows = [["", before.name, after.name, "Change"]]
        for (old, new) in zip(before.metrics, after.metrics) where old.value != nil || new.value != nil {
            rows.append([old.label, format(old.value, old.unit), format(new.value, new.unit), change(old, new)])
        }
        let widths = (0..<4).map { column in rows.map { $0[column].count }.max() ?? 0 }
        return rows.map { row in
            row.enumerated().map { column, cell in
                column == 0 ? cell.padding(toLength: widths[column], withPad: " ", startingAt: 0)
                            : String(repeating: " ", count: widths[column] - cell.count) + cell
            }.joined(separator: "   ")
        }.joined(separator: "\n")
    }

    /// "+12.5% better" style change, judged by whether higher is better for this metric.
    static func change(_ old: RunMetrics.Metric, _ new: RunMetrics.Metric) -> String {
        guard let a = old.value, let b = new.value, a != 0 else { return "" }
        let percent = (b - a) / abs(a) * 100
        guard abs(percent) >= 0.5 else { return "same" }
        guard let higherIsBetter = old.higherIsBetter else { return String(format: "%+.1f%%", percent) }
        let better = (percent > 0) == higherIsBetter
        return String(format: "%+.1f%% %@", percent, better ? "better" : "worse")
    }

    private static func format(_ value: Double?, _ unit: String) -> String {
        guard let value else { return "--" }
        let number = value >= 100 || value == value.rounded() ? String(format: "%.0f", value) : String(format: "%.1f", value)
        return unit.isEmpty ? number : "\(number) \(unit)"
    }
}
