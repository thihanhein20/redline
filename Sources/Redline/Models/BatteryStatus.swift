/// Battery charge and drain. Absent on Macs without a battery.
struct BatteryStatus {
    var percent: Int
    var isCharging: Bool
    var onBattery: Bool
    /// Power flowing out of (positive) or into (negative) the battery.
    var drainWatts: Double?
}
