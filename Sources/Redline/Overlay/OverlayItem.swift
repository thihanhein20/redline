/// One line of the overlay: a labelled reading, a graph, the memory bar, or a marker flash.
enum OverlayItem: Equatable {
    enum Emphasis { case normal, warning, hot }

    case stat(label: String, value: String, emphasis: Emphasis = .normal)
    case fpsGraph
    case frameTimeGraph
    case gameMemoryGraph
    case memoryBar(MemoryBreakdown)
    case marker(Int)

    var label: String? {
        if case .stat(let label, _, _) = self { return label }
        return nil
    }
}
