import IOKit

/// GPU usage (0–100 %) read from the GPU driver's IORegistry statistics.
struct GPUService {
    func usage() -> Double? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            if let utilization = performanceStatistics(of: entry)?["Device Utilization %"] as? Int {
                return Double(utilization)
            }
        }
        return nil
    }

    private func performanceStatistics(of entry: io_registry_entry_t) -> [String: Any]? {
        IORegistryEntryCreateCFProperty(entry, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? [String: Any]
    }
}
