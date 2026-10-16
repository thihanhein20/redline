/// The most recent readings, oldest first. `nil` marks a second with no reading (e.g. no game running).
struct History {
    let capacity: Int
    private(set) var values: [Double?] = []

    init(capacity: Int) {
        self.capacity = capacity
    }

    mutating func append(_ value: Double?) {
        values.append(value)
        if values.count > capacity { values.removeFirst(values.count - capacity) }
    }
}
