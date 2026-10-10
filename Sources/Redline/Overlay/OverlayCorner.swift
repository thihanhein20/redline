import SwiftUI

/// Screen corner the overlay is pinned to.
enum OverlayCorner: String, CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight

    var title: String {
        switch self {
        case .topLeft: "Top Left"
        case .topRight: "Top Right"
        case .bottomLeft: "Bottom Left"
        case .bottomRight: "Bottom Right"
        }
    }

    var alignment: Alignment {
        switch self {
        case .topLeft: .topLeading
        case .topRight: .topTrailing
        case .bottomLeft: .bottomLeading
        case .bottomRight: .bottomTrailing
        }
    }

    /// Origin for a window of `size` in this corner of `area`, inset by `margin`.
    func origin(for size: CGSize, in area: CGRect, margin: CGFloat) -> CGPoint {
        let isLeft = self == .topLeft || self == .bottomLeft
        let isTop = self == .topLeft || self == .topRight
        return CGPoint(
            x: isLeft ? area.minX + margin : area.maxX - size.width - margin,
            y: isTop ? area.maxY - size.height - margin : area.minY + margin
        )
    }
}
