import CoreGraphics
import Testing
@testable import Redline

struct SparklineTests {
    private let size = CGSize(width: 40, height: 10)

    @Test func gapsSplitTheLine() {
        let segments = Sparkline.segments([60, 30, nil, 0], capacity: 5, top: 60, in: size)
        // capacity 5 over 40 px → 10 px per reading; 4 readings start one step in.
        #expect(segments == [[CGPoint(x: 10, y: 0), CGPoint(x: 20, y: 5)], [CGPoint(x: 40, y: 10)]])
    }

    @Test func valuesAboveTopAreClipped() {
        let segments = Sparkline.segments([120], capacity: 2, top: 60, in: size)
        #expect(segments == [[CGPoint(x: 40, y: 0)]])
    }
}
