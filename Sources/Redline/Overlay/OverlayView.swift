import SwiftUI

/// The stats readout drawn inside the overlay panel.
struct OverlayView: View {
    let monitor: StatsMonitor

    var body: some View {
        let stats = monitor.stats
        VStack(alignment: .leading, spacing: 3) {
            StatRow(label: "CPU", value: StatFormat.percent(stats.cpuUsage))
            StatRow(label: "GPU", value: StatFormat.percent(stats.gpuUsage))
            StatRow(label: "RAM", value: StatFormat.memory(used: stats.memoryUsedGB, total: stats.memoryTotalGB))
            StatRow(label: "TEMP", value: StatFormat.celsius(stats.socTemperature),
                    isHot: StatFormat.isHot(stats.socTemperature))
            StatRow(label: "THERM", value: StatFormat.thermal(stats.thermalState),
                    isHot: stats.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue)
        }
        .font(.system(size: 12, weight: .semibold, design: .monospaced))
        .padding(10)
        .frame(width: 190, alignment: .leading)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    var isHot = false

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.red)
            Spacer()
            Text(value).foregroundStyle(isHot ? .red : .white)
        }
    }
}
