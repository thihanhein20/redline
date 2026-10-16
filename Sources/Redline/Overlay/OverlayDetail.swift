/// How much the overlay shows: the essentials, or everything Redline measures.
enum OverlayDetail: String, CaseIterable {
    case compact, full

    var title: String {
        switch self {
        case .compact: "Compact"
        case .full: "Full"
        }
    }
}
