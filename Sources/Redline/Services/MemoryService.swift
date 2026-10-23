import Darwin
import Foundation

/// RAM: usage (Activity Monitor's "Memory Used"), breakdown, pressure, swap size and swap activity.
final class MemoryService {
    struct Reading {
        var usedGB: Double
        var breakdown: MemoryBreakdown
        /// Data read back from / written out to swap on disk; when this is busy, games stutter.
        var swapInMBps: Double?
        var swapOutMBps: Double?
    }

    private let host = mach_host_self()
    private let bytesPerGB = 1_073_741_824.0
    private let pageBytes = Double(getpagesize())
    private var previousSwap: (ins: UInt64, outs: UInt64, time: UInt64)?

    var totalGB: Double {
        Double(ProcessInfo.processInfo.physicalMemory) / bytesPerGB
    }

    func sample() -> Reading? {
        guard let stats = vmStatistics() else { return nil }
        let gigabytes = { (pages: UInt64) in Double(pages) * self.pageBytes / self.bytesPerGB }
        let app = UInt64(stats.internal_page_count) - UInt64(stats.purgeable_count)
        let breakdown = MemoryBreakdown(
            appGB: gigabytes(app),
            wiredGB: gigabytes(UInt64(stats.wire_count)),
            compressedGB: gigabytes(UInt64(stats.compressor_page_count)),
            cachedGB: gigabytes(UInt64(stats.external_page_count) + UInt64(stats.purgeable_count))
        )
        var reading = Reading(usedGB: breakdown.appGB + breakdown.wiredGB + breakdown.compressedGB, breakdown: breakdown)

        let now = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        if let previous = previousSwap, now > previous.time, stats.swapins >= previous.ins, stats.swapouts >= previous.outs {
            let megabytesPerSecond = pageBytes / 1_048_576 / (Double(now - previous.time) / 1e9)
            reading.swapInMBps = Double(stats.swapins - previous.ins) * megabytesPerSecond
            reading.swapOutMBps = Double(stats.swapouts - previous.outs) * megabytesPerSecond
        }
        previousSwap = (stats.swapins, stats.swapouts, now)
        return reading
    }

    /// Activity Monitor's memory pressure colour: when it's not normal, games start to stutter.
    func pressure() -> MemoryPressure? {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else { return nil }
        return MemoryPressure(rawValue: Int(level))
    }

    /// Memory swapped out to disk.
    func swapUsedGB() -> Double? {
        var swap = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &swap, &size, nil, 0) == 0 else { return nil }
        return Double(swap.xsu_used) / bytesPerGB
    }

    private func vmStatistics() -> vm_statistics64? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        return result == KERN_SUCCESS ? stats : nil
    }
}
