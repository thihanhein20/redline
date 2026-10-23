import Testing
@testable import Redline

struct BatteryServiceTests {
    @Test func dischargingIsPositiveDrain() {
        // -1500 mA at 12.0 V, reported by the driver as an unsigned 64-bit number.
        let raw = UInt64(bitPattern: -1500)
        #expect(BatteryService.drainWatts(rawAmperage: raw, millivolts: 12_000) == 18)
    }

    @Test func chargingIsNegativeDrain() {
        #expect(BatteryService.drainWatts(rawAmperage: 500, millivolts: 12_000) == -6)
    }
}
