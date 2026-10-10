import Darwin
import Foundation

/// RAM usage, matching Activity Monitor's "Memory Used" (app + wired + compressed).
final class MemoryService {
    private let host = mach_host_self()
    private let bytesPerGB = 1_073_741_824.0

    var totalGB: Double {
        Double(ProcessInfo.processInfo.physicalMemory) / bytesPerGB
    }

    func usedGB() -> Double? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let appPages = UInt64(stats.internal_page_count) - UInt64(stats.purgeable_count)
        let usedPages = appPages + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        return Double(usedPages) * Double(getpagesize()) / bytesPerGB
    }
}
