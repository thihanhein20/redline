import Darwin

/// CPU and memory use of a single process (the game), measured between calls.
final class ProcessService {
    private var previous: (processID: Int32, cpuTicks: UInt64, time: UInt64)?
    private let timebase: Double = {
        var info = mach_timebase_info()
        mach_timebase_info(&info)
        return Double(info.numer) / Double(info.denom)
    }()

    func stats(for processID: Int32) -> GameProcess? {
        var usage = rusage_info_v4()
        let result = withUnsafeMutablePointer(to: &usage) {
            $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { proc_pid_rusage(processID, RUSAGE_INFO_V4, $0) }
        }
        guard result == 0 else { return nil }

        // On Apple Silicon these CPU times are mach ticks, not nanoseconds.
        let cpuTicks = usage.ri_user_time + usage.ri_system_time, now = mach_absolute_time()
        defer { previous = (processID, cpuTicks, now) }
        var cpuPercent: Double?
        if let previous, previous.processID == processID, now > previous.time, cpuTicks >= previous.cpuTicks {
            cpuPercent = Double(cpuTicks - previous.cpuTicks) / Double(now - previous.time) * 100
        }
        return GameProcess(processID: processID, name: Self.name(of: processID), cpuPercent: cpuPercent,
                           memoryMB: Double(usage.ri_phys_footprint) / 1_048_576)
    }

    private static func name(of processID: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        proc_name(processID, &buffer, UInt32(buffer.count))
        return String(decoding: buffer.prefix { $0 != 0 }.map(UInt8.init), as: UTF8.self)
    }
}
