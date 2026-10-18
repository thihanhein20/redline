import Darwin

/// One process's (the game's) CPU, memory, energy, disk and threads, measured between calls.
final class ProcessService {
    private struct Sample {
        let processID: Int32
        let time: UInt64
        let usage: rusage_info_v6
    }

    private var previous: Sample?
    /// Mach ticks → nanoseconds.
    private let timebase: Double = {
        var info = mach_timebase_info()
        mach_timebase_info(&info)
        return Double(info.numer) / Double(info.denom)
    }()

    func stats(for processID: Int32) -> GameProcess? {
        var usage = rusage_info_v6()
        let result = withUnsafeMutablePointer(to: &usage) {
            $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { proc_pid_rusage(processID, RUSAGE_INFO_V6, $0) }
        }
        guard result == 0 else { return nil }

        let current = Sample(processID: processID, time: mach_absolute_time(), usage: usage)
        defer { previous = current }
        var game = GameProcess(processID: processID, name: Self.name(of: processID),
                               memoryMB: Double(usage.ri_phys_footprint) / 1_048_576, threads: Self.threads(of: processID))
        guard let previous, previous.processID == processID, current.time > previous.time else { return game }

        let ticks = Double(current.time - previous.time), seconds = ticks * timebase / 1e9
        let old = previous.usage
        // On Apple Silicon these CPU times are mach ticks, like `time`, so the ratio needs no conversion.
        game.cpuPercent = rate(usage.ri_user_time + usage.ri_system_time, old.ri_user_time + old.ri_system_time, per: ticks).map { $0 * 100 }
        game.cpuPowerWatts = rate(usage.ri_energy_nj, old.ri_energy_nj, per: seconds).map { $0 / 1e9 }
        game.diskReadMBps = rate(usage.ri_diskio_bytesread, old.ri_diskio_bytesread, per: seconds).map { $0 / 1_048_576 }
        game.diskWriteMBps = rate(usage.ri_diskio_byteswritten, old.ri_diskio_byteswritten, per: seconds).map { $0 / 1_048_576 }
        return game
    }

    private func rate(_ new: UInt64, _ old: UInt64, per interval: Double) -> Double? {
        new >= old && interval > 0 ? Double(new - old) / interval : nil
    }

    private static func threads(of processID: Int32) -> Int? {
        var info = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        return proc_pidinfo(processID, PROC_PIDTASKINFO, 0, &info, size) == size ? Int(info.pti_threadnum) : nil
    }

    private static func name(of processID: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        proc_name(processID, &buffer, UInt32(buffer.count))
        return String(decoding: buffer.prefix { $0 != 0 }.map(UInt8.init), as: UTF8.self)
    }
}
