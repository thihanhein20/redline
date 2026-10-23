import Sensors

/// Chip temperatures: CPU and GPU from SMC sensors, the SoC die from HID sensors as a fallback.
struct TemperatureService {
    /// Hottest CPU core sensor (SMC "Tp…").
    func cpu() -> Double? { reading(smc_max_temperature("Tp")) }

    /// Hottest GPU sensor (SMC "Tg…").
    func gpu() -> Double? { reading(smc_max_temperature("Tg")) }

    /// Hottest SoC die sensor (HID "PMU tdie…"), for chips whose SMC keys differ.
    func soc() -> Double? { reading(hid_max_temperature("tdie")) }

    private func reading(_ celsius: Double) -> Double? {
        celsius.isNaN ? nil : celsius
    }
}
