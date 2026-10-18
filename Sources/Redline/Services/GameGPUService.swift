import Foundation
import IOKit

/// One process's share of GPU time (Activity Monitor's "% GPU"), from the GPU driver's per-app accounting.
final class GameGPUService {
    private var previous: (processID: Int32, gpuNanoseconds: UInt64, time: UInt64)?

    func usage(of processID: Int32) -> Double? {
        let gpuTime = Self.accumulatedGPUTime(of: processID)
        let now = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        defer { previous = gpuTime.map { (processID, $0, now) } }
        guard let gpuTime, let previous, previous.processID == processID,
              now > previous.time, gpuTime >= previous.gpuNanoseconds else { return nil }
        return min(100, Double(gpuTime - previous.gpuNanoseconds) / Double(now - previous.time) * 100)
    }

    /// Sum of `accumulatedGPUTime` (ns) over the GPU clients the process has opened. `nil` if it has none.
    static func accumulatedGPUTime(of processID: Int32) -> UInt64? {
        let owner = "pid \(processID),"
        var total: UInt64?
        GPUService.forEachAccelerator { accelerator in
            var children: io_iterator_t = 0
            guard IORegistryEntryGetChildIterator(accelerator, kIOServicePlane, &children) == KERN_SUCCESS else { return }
            defer { IOObjectRelease(children) }
            while case let client = IOIteratorNext(children), client != 0 {
                defer { IOObjectRelease(client) }
                guard let creator = property(client, "IOUserClientCreator") as? String, creator.hasPrefix(owner),
                      let usage = property(client, "AppUsage") as? [[String: Any]] else { continue }
                total = (total ?? 0) + usage.compactMap { ($0["accumulatedGPUTime"] as? NSNumber)?.uint64Value }.reduce(0, +)
            }
        }
        return total
    }

    private static func property(_ entry: io_registry_entry_t, _ key: String) -> Any? {
        IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }
}
