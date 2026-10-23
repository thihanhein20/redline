import CoreGraphics
import Testing
@testable import Redline

struct SparklineTests {
    private let size = CGSize(width: 40, height: 10)

    @Test func gapsSplitTheLine() {
        let segments = Sparkline.segments([60, 30, nil, 0], capacity: 5, range: 0...60, in: size)
        // capacity 5 over 40 px → 10 px per reading; 4 readings start one step in.
        #expect(segments == [[CGPoint(x: 10, y: 0), CGPoint(x: 20, y: 5)], [CGPoint(x: 40, y: 10)]])
    }

    @Test func valuesOutsideTheRangeAreClipped() {
        let segments = Sparkline.segments([120], capacity: 2, range: 0...60, in: size)
        #expect(segments == [[CGPoint(x: 40, y: 0)]])
    }

    @Test func zoomedRangeShowsSmallChanges() {
        // 1200 → 1210 MB fills the whole height when the range is 1200...1210.
        let segments = Sparkline.segments([1200, 1210], capacity: 2, range: 1200...1210, in: size)
        #expect(segments == [[CGPoint(x: 0, y: 10), CGPoint(x: 40, y: 0)]])
    }
}
