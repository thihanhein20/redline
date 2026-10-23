import SwiftUI

/// Activity Monitor-style split of RAM: app, wired, compressed, cached.
struct MemoryBar: View {
    let breakdown: MemoryBreakdown
    let totalGB: Double

    private var parts: [(name: String, gb: Double, color: Color)] {
        [("App", breakdown.appGB, .blue), ("Wired", breakdown.wiredGB, .orange),
         ("Comp", breakdown.compressedGB, .purple), ("Cache", breakdown.cachedGB, .gray)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            GeometryReader { geometry in
                HStack(spacing: 1) {
                    ForEach(parts, id: \.name) { part in
                        part.color.frame(width: max(0, geometry.size.width * part.gb / max(totalGB, 0.1) - 1))
                    }
                }
            }
            .frame(height: 6)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 2))
            Grid(horizontalSpacing: 8, verticalSpacing: 1) {
                GridRow { legend(parts[0]); legend(parts[1]) }
                GridRow { legend(parts[2]); legend(parts[3]) }
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
        }
        .padding(.bottom, 2)
    }

    private func legend(_ part: (name: String, gb: Double, color: Color)) -> some View {
        HStack(spacing: 3) {
            Circle().fill(part.color).frame(width: 5, height: 5)
            Text(part.name).foregroundStyle(.white.opacity(0.6))
            Spacer(minLength: 2)
            Text(String(format: "%.1f", part.gb)).foregroundStyle(.white.opacity(0.85))
        }
    }
}
