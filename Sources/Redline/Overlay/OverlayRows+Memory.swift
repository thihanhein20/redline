/// The overlay's game and memory sections.
extension OverlayRows {
    /// Memory growing faster than this for a minute is worth a look (possible leak).
    static let leakWarningMBPerMinute = 10.0

    static func gameRows(_ game: GameProcess) -> [OverlayItem] {
        let growth = game.memoryGrowthMBPerMinute ?? 0
        var items: [OverlayItem] = [
            .stat(label: "GAME", value: String(game.name.prefix(14))),
            .stat(label: "GAME CPU", value: StatFormat.percent(game.cpuPercent)),
        ]
        if let gpu = game.gpuPercent { items.append(.stat(label: "GAME GPU", value: StatFormat.percent(gpu))) }
        items += [
            .stat(label: "GAME MEM", value: StatFormat.gameMemory(game),
                  emphasis: growth >= leakWarningMBPerMinute ? .warning : .normal),
            .gameMemoryGraph,
        ]
        if let metal = game.metalMemoryMB { items.append(.stat(label: "GAME VRAM", value: String(format: "%.0f MB", metal))) }
        if let watts = game.cpuPowerWatts { items.append(.stat(label: "GAME CPU PWR", value: StatFormat.watts(watts))) }
        if let disk = StatFormat.disk(read: game.diskReadMBps, write: game.diskWriteMBps) {
            items.append(.stat(label: "GAME DISK", value: disk))
        }
        if let threads = game.threads { items.append(.stat(label: "THREADS", value: "\(threads)")) }
        return items
    }

    static func memoryRows(_ stats: SystemStats, full: Bool) -> [OverlayItem] {
        let pressure: OverlayItem.Emphasis = switch stats.memoryPressure {
        case .critical: .hot
        case .warning: .warning
        default: .normal
        }
        var items: [OverlayItem] = [
            .stat(label: "RAM", value: StatFormat.memory(used: stats.memoryUsedGB, total: stats.memoryTotalGB), emphasis: pressure),
        ]
        guard full else { return items }
        if let breakdown = stats.memoryBreakdown { items.append(.memoryBar(breakdown)) }
        if let swap = stats.swapUsedGB, swap >= 0.05 {
            let activity = (stats.swapInMBps ?? 0) + (stats.swapOutMBps ?? 0)
            items.append(.stat(label: "SWAP", value: StatFormat.swap(usedGB: swap, activityMBps: activity),
                               emphasis: activity >= 1 ? .hot : .warning))
        }
        if let gpuMemory = stats.gpuMemoryMB { items.append(.stat(label: "GPU MEM", value: String(format: "%.0f MB", gpuMemory))) }
        return items
    }
}
