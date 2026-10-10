import CoreGraphics
import Testing
@testable import Redline

struct OverlayCornerTests {
    // Screen area from (0, 0) to (1000, 800); macOS y grows upward.
    private let area = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let size = CGSize(width: 200, height: 100)

    @Test(arguments: [
        (OverlayCorner.topLeft, CGPoint(x: 10, y: 690)),
        (.topRight, CGPoint(x: 790, y: 690)),
        (.bottomLeft, CGPoint(x: 10, y: 10)),
        (.bottomRight, CGPoint(x: 790, y: 10)),
    ])
    func originIsInsetFromCorner(corner: OverlayCorner, expected: CGPoint) {
        #expect(corner.origin(for: size, in: area, margin: 10) == expected)
    }
}
