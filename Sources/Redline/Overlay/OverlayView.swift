import SwiftUI

/// The stats readout drawn inside the overlay panel.
struct OverlayView: View {
    let monitor: StatsMonitor
    let settings: OverlayController

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(KeyShortcut.toggleSettings.symbol) Settings   \(KeyShortcut.addMarker.symbol) Mark")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                row(for: item)
            }
        }
        .font(.system(size: 12, weight: .semibold, design: .monospaced))
        .padding(10)
        .frame(width: 200, alignment: .leading)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
    }

    private var items: [OverlayItem] {
        // A marker stays on screen for 3 seconds after the hotkey.
        let marker = monitor.lastMarker.flatMap { Date().timeIntervalSince($0.at) < 3 ? $0.number : nil }
        return OverlayRows.items(for: monitor.stats, detail: settings.detail, marker: marker)
    }

    @ViewBuilder
    private func row(for item: OverlayItem) -> some View {
        switch item {
        case .stat(let label, let value, let emphasis):
            StatRow(label: label, value: value, emphasis: emphasis)
        case .fpsGraph:
            Sparkline(values: monitor.fpsHistory.values, capacity: monitor.fpsHistory.capacity)
                .frame(height: 24)
                .padding(.bottom, 2)
        case .frameTimeGraph:
            // Frame times (ms): spikes upward are hitches. Scale covers at least 30 FPS (33 ms).
            Sparkline(values: monitor.stats.pacing?.frameTimesMS ?? [], capacity: 120, minimumTop: 33.4, color: .orange)
                .frame(height: 20)
                .padding(.bottom, 2)
        case .marker(let number):
            Text("● MARKER \(number)")
                .foregroundStyle(.yellow)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let emphasis: OverlayItem.Emphasis

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.red)
            Spacer()
            Text(value).foregroundStyle(valueColor)
        }
    }

    private var valueColor: Color {
        switch emphasis {
        case .normal: .white
        case .warning: .orange
        case .hot: .red
        }
    }
}
