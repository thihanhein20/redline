import SwiftUI

/// A tiny line graph of recent readings, scaled from 0 to at least `minimumTop`.
/// Gaps (`nil`) break the line, so "no game running" never looks like "0 FPS".
struct Sparkline: View {
    let values: [Double?]
    let capacity: Int
    var minimumTop = 60.0

    var body: some View {
        Canvas { context, size in
            let top = max(minimumTop, values.compactMap { $0 }.max() ?? 0)
            // Keep the line inside the box at 0 and at `top`.
            let inset: CGFloat = 2
            context.translateBy(x: 0, y: inset)
            let area = CGSize(width: size.width, height: size.height - inset * 2)
            for segment in Self.segments(values, capacity: capacity, top: top, in: area) {
                var line = Path()
                line.addLines(segment)
                context.stroke(line, with: .color(.red), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            }
        }
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 3))
        .accessibilityLabel("FPS over the last \(capacity) seconds")
    }

    /// Points for each unbroken run of readings. The newest reading sits at the right edge.
    nonisolated static func segments(_ values: [Double?], capacity: Int, top: Double, in size: CGSize) -> [[CGPoint]] {
        guard capacity > 1, top > 0 else { return [] }
        let step = size.width / CGFloat(capacity - 1)
        let offset = capacity - values.count  // fewer readings than capacity: start further right
        var segments: [[CGPoint]] = [[]]
        for (index, value) in values.enumerated() {
            guard let value else {
                if !segments[segments.count - 1].isEmpty { segments.append([]) }
                continue
            }
            let x = CGFloat(index + offset) * step
            let y = size.height * (1 - CGFloat(min(value, top) / top))
            segments[segments.count - 1].append(CGPoint(x: x, y: y))
        }
        return segments.filter { !$0.isEmpty }
    }
}
