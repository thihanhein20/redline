import Darwin

/// Cumulative CPU ticks summed over all cores.
struct CPUTicks: Equatable {
    var busy: UInt64
    var total: UInt64
}

/// Total CPU usage (0–100 %) across all cores, measured between two calls.
final class CPUService {
    private let host = mach_host_self()
    private var previous: CPUTicks?

    /// Returns `nil` on the first call, since usage needs two samples.
    func usage() -> Double? {
        guard let current = readTicks() else { return nil }
        defer { previous = current }
        guard let previous else { return nil }
        return Self.usage(from: previous, to: current)
    }

    static func usage(from old: CPUTicks, to new: CPUTicks) -> Double? {
        guard new.total > old.total, new.busy >= old.busy else { return nil }
        return Double(new.busy - old.busy) / Double(new.total - old.total) * 100
    }

    private func readTicks() -> CPUTicks? {
        var coreCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        guard host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &coreCount, &info, &infoCount) == KERN_SUCCESS,
              let info else { return nil }
        defer {
            let size = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }

        let cores = UnsafeBufferPointer(
            start: UnsafeRawPointer(info).assumingMemoryBound(to: processor_cpu_load_info.self),
            count: Int(coreCount)
        )
        return cores.reduce(into: CPUTicks(busy: 0, total: 0)) { sum, core in
            let (user, system, idle, nice) = core.cpu_ticks
            let busy = UInt64(user) + UInt64(system) + UInt64(nice)
            sum.busy += busy
            sum.total += busy + UInt64(idle)
        }
    }
}
