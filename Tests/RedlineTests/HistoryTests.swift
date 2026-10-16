import Testing
@testable import Redline

struct HistoryTests {
    @Test func keepsOnlyTheNewestReadings() {
        var history = History(capacity: 3)
        for value in [10.0, nil, 30, 40] { history.append(value) }
        #expect(history.values == [nil, 30, 40])
    }
}
