import SwiftUI

/// Summary of the last play session, shown in settings once a game has been measured.
struct LastSessionView: View {
    let summary: SessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Last Session")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 3) {
                ForEach(SessionReport.lines(for: summary), id: \.label) { line in
                    GridRow {
                        Text(line.label).foregroundStyle(.secondary)
                        Text(line.value).monospacedDigit().textSelection(.enabled)
                    }
                }
            }
            .font(.caption)
            .padding(.horizontal, 8)
        }
    }
}
