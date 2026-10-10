import HIDSensors

/// Chip temperatures from Apple Silicon's HID sensors.
struct TemperatureService {
    /// Hottest SoC die sensor ("PMU tdie*").
    // ponytail: HID sensors don't label CPU vs GPU on M2; read SMC keys (Tp*/Tg*) to split them.
    func socTemperature() -> Double? {
        let celsius = hid_max_temperature("tdie")
        return celsius.isNaN ? nil : celsius
    }
}
