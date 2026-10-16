import Sensors

/// Chip power and clock speeds from IOReport, measured between calls.
struct PowerService {
    /// `nil` on the first call, which only starts measuring.
    func sample() -> ChipPower? {
        let sample = soc_sample()
        guard sample.valid else { return nil }
        return ChipPower(
            cpuWatts: reading(sample.cpuWatts),
            gpuWatts: reading(sample.gpuWatts),
            totalWatts: reading(sample.totalWatts),
            eCoreMHz: reading(sample.eCoreMHz),
            pCoreMHz: reading(sample.pCoreMHz),
            gpuMHz: reading(sample.gpuMHz)
        )
    }

    private func reading(_ value: Double) -> Double? {
        value.isNaN ? nil : value
    }
}
