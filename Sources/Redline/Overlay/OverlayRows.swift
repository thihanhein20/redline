import Foundation

/// Decides which lines the overlay shows for a snapshot. Rows without a reading on this Mac are left out.
enum OverlayRows {
    static func items(for stats: SystemStats, detail: OverlayDetail, marker: Int? = nil) -> [OverlayItem] {
        let full = detail == .full
        var items: [OverlayItem] = []
        if let marker { items.append(.marker(marker)) }

        items += [.stat(label: "FPS", value: StatFormat.fps(stats.fps)), .fpsGraph]
        if let pacing = stats.pacing {
            if let low = pacing.onePercentLowFPS { items.append(.stat(label: "1% LOW", value: StatFormat.whole(low))) }
            if full {
                items.append(.stat(label: "STUTTERS", value: "\(pacing.stutters)", emphasis: pacing.stutters > 0 ? .warning : .normal))
                if !pacing.frameTimesMS.isEmpty { items.append(.frameTimeGraph) }
            }
        }
        if full, let gpuMS = stats.gpuFrameMS { items.append(.stat(label: "GPU TIME", value: String(format: "%.2fms", gpuMS))) }
        if full, let hz = stats.displayHz { items.append(.stat(label: "DISPLAY", value: "\(hz) Hz")) }

        items += [.stat(label: "CPU", value: StatFormat.percent(stats.cpuUsage)),
                  .stat(label: "GPU", value: StatFormat.percent(stats.gpuUsage))]
        if full, let game = stats.game { items += gameRows(game) }
        items += memoryRows(stats, full: full)
        items += temperatures(stats, full: full)
        if full { items += powerAndBattery(stats) }
        items.append(.stat(label: "THERM", value: StatFormat.thermal(stats.thermalState), emphasis: thermalEmphasis(stats.thermalState)))
        return items
    }

    private static func temperatures(_ stats: SystemStats, full: Bool) -> [OverlayItem] {
        guard let cpu = stats.cpuTemperature, let gpu = stats.gpuTemperature else {
            return [.stat(label: "TEMP", value: StatFormat.celsius(stats.socTemperature), emphasis: heat(stats.socTemperature))]
        }
        guard full else {
            return [.stat(label: "TEMP", value: "C\(StatFormat.whole(cpu))° G\(StatFormat.whole(gpu))°", emphasis: heat(max(cpu, gpu)))]
        }
        return [.stat(label: "CPU TEMP", value: StatFormat.celsius(cpu), emphasis: heat(cpu)),
                .stat(label: "GPU TEMP", value: StatFormat.celsius(gpu), emphasis: heat(gpu))]
    }

    private static func powerAndBattery(_ stats: SystemStats) -> [OverlayItem] {
        var items: [OverlayItem] = []
        if let watts = stats.power?.totalWatts { items.append(.stat(label: "POWER", value: StatFormat.watts(watts))) }
        if let mhz = stats.power?.pCoreMHz ?? stats.power?.eCoreMHz { items.append(.stat(label: "CPU CLK", value: StatFormat.gigahertz(mhz))) }
        if let mhz = stats.power?.gpuMHz { items.append(.stat(label: "GPU CLK", value: StatFormat.gigahertz(mhz))) }
        if let battery = stats.battery { items.append(.stat(label: "BATTERY", value: StatFormat.battery(battery))) }
        return items
    }

    private static func heat(_ celsius: Double?) -> OverlayItem.Emphasis {
        StatFormat.isHot(celsius) ? .hot : .normal
    }

    private static func thermalEmphasis(_ state: ProcessInfo.ThermalState) -> OverlayItem.Emphasis {
        switch state {
        case .nominal: .normal
        case .fair: .warning
        default: .hot
        }
    }
}
