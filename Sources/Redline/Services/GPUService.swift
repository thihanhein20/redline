import IOKit

/// Whole-GPU usage and memory, from the GPU driver's IORegistry statistics.
struct GPUService {
    struct Reading {
        var usage: Double?
        var memoryInUseMB: Double?
    }

    func sample() -> Reading {
        var reading = Reading()
        Self.forEachAccelerator { accelerator in
            guard let stats = IORegistryEntryCreateCFProperty(accelerator, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? [String: Any] else { return }
            if let utilization = stats["Device Utilization %"] as? Int { reading.usage = Double(utilization) }
            if let bytes = stats["In use system memory"] as? Int { reading.memoryInUseMB = Double(bytes) / 1_048_576 }
        }
        return reading
    }

    /// Calls `body` with each GPU's IORegistry entry (Apple Silicon Macs have one).
    static func forEachAccelerator(_ body: (io_registry_entry_t) -> Void) {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS else { return }
        defer { IOObjectRelease(iterator) }
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            body(entry)
            IOObjectRelease(entry)
        }
    }
}
