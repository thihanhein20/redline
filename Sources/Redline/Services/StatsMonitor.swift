import Foundation
import Observation

/// Polls every service on a fixed interval and publishes the latest `SystemStats`.
@MainActor
@Observable
final class StatsMonitor {
    private(set) var stats = SystemStats()
    /// FPS for the last 60 seconds, for the overlay's graph.
    private(set) var fpsHistory = History(capacity: 60)
    /// Called after every refresh, e.g. for logging.
    @ObservationIgnored var onUpdate: ((SystemStats) -> Void)?

    @ObservationIgnored private let fps = FPSService()
    @ObservationIgnored private let hudFPS = HUDLogFPSService()
    @ObservationIgnored private let cpu = CPUService()
    @ObservationIgnored private let gpu = GPUService()
    @ObservationIgnored private let memory = MemoryService()
    @ObservationIgnored private let temperature = TemperatureService()
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    func start(interval: Duration = .seconds(1)) {
        pollTask?.cancel()
        hudFPS.start()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: interval)
            }
        }
    }

    func stop() {
        hudFPS.stop()
        pollTask?.cancel()
        pollTask = nil
    }

    private func refresh() {
        stats = SystemStats(
            // Hook FPS (games run via `redline run`) is exact and uncapped; HUD log covers every other game.
            fps: fps.fps() ?? hudFPS.fps(),
            cpuUsage: cpu.usage(),
            gpuUsage: gpu.usage(),
            memoryUsedGB: memory.usedGB(),
            memoryTotalGB: memory.totalGB,
            socTemperature: temperature.socTemperature(),
            thermalState: ProcessInfo.processInfo.thermalState
        )
        fpsHistory.append(stats.fps)
        onUpdate?(stats)
    }
}
