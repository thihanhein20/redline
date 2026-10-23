import IOKit

/// Battery level and drain from the AppleSmartBattery driver. `nil` on Macs without a battery.
struct BatteryService {
    func status() -> BatteryStatus? {
        let battery = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard battery != 0 else { return nil }
        defer { IOObjectRelease(battery) }

        func value<T>(_ key: String) -> T? {
            IORegistryEntryCreateCFProperty(battery, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? T
        }
        guard let percent: Int = value("CurrentCapacity") else { return nil }
        let external: Bool = value("ExternalConnected") ?? false
        return BatteryStatus(
            percent: percent,
            isCharging: value("IsCharging") ?? false,
            onBattery: !external,
            drainWatts: Self.drainWatts(rawAmperage: value("InstantAmperage"), millivolts: value("Voltage"))
        )
    }

    /// The driver reports signed milliamps as an unsigned 64-bit number; negative = discharging.
    static func drainWatts(rawAmperage: UInt64?, millivolts: Int?) -> Double? {
        guard let rawAmperage, let millivolts else { return nil }
        let milliamps = Double(Int64(bitPattern: rawAmperage))
        return -milliamps * Double(millivolts) / 1_000_000
    }
}
