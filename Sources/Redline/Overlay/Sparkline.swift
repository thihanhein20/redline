import SwiftUI

/// A tiny line graph of recent readings (FPS per second, frame times, or memory).
/// Gaps (`nil`) break the line, so "no game running" never looks like "0 FPS".
struct Sparkline: View {
    let values: [Double?]
    let capacity: Int
    /// The scale always reaches at least this high.
    var minimumTop = 60.0
    var color = Color.red
    /// `false` zooms in on the readings' own range, so small changes (like slow memory growth) stay visible.
    var startsAtZero = true

    var body: some View {
        Canvas { context, size in
            let readings = values.compactMap { $0 }
            let bottom = startsAtZero ? 0 : (readings.min() ?? 0)
            let top = max(startsAtZero ? minimumTop : bottom + minimumTop, readings.max() ?? 0)
            // Keep the line inside the box at both ends of the scale.
            let inset: CGFloat = 2
            context.translateBy(x: 0, y: inset)
            let area = CGSize(width: size.width, height: size.height - inset * 2)
            for segment in Self.segments(values, capacity: capacity, range: bottom...top, in: area) {
                var line = Path()
                line.addLines(segment)
                context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            }
        }
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 3))
    }

    /// Points for each unbroken run of readings. The newest reading sits at the right edge.
    nonisolated static func segments(_ values: [Double?], capacity: Int, range: ClosedRange<Double>, in size: CGSize) -> [[CGPoint]] {
        let span = range.upperBound - range.lowerBound
        guard capacity > 1, span > 0 else { return [] }
        let step = size.width / CGFloat(capacity - 1)
        let offset = capacity - values.count  // fewer readings than capacity: start further right
        var segments: [[CGPoint]] = [[]]
        for (index, value) in values.enumerated() {
            guard let value else {
                if !segments[segments.count - 1].isEmpty { segments.append([]) }
                continue
            }
            let x = CGFloat(index + offset) * step
            let clamped = min(max(value, range.lowerBound), range.upperBound)
            let y = size.height * (1 - CGFloat((clamped - range.lowerBound) / span))
            segments[segments.count - 1].append(CGPoint(x: x, y: y))
        }
        return segments.filter { !$0.isEmpty }
    }
}
