import SwiftUI

/// The last play session's highlights, shown in settings. The full summary goes to the saved .txt and Terminal.
struct LastSessionView: View {
    let summary: SessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Last Session")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 3) {
                ForEach(SessionReport.highlights(for: summary), id: \.label) { line in
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
