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
    /// The game started by `redline run`, if any; otherwise the game is whichever reports FPS.
    @ObservationIgnored var launchedGameID: Int32?
    /// Last marker added with the hotkey, for the overlay to show briefly.
    private(set) var lastMarker: (number: Int, at: Date)?
    @ObservationIgnored private var pendingMarker: Int?

    @ObservationIgnored private let fps = FPSService()
    @ObservationIgnored private let hudFPS = HUDLogFPSService()
    @ObservationIgnored private let frameTiming = FrameTimingService()
    @ObservationIgnored private let cpu = CPUService()
    @ObservationIgnored private let gpu = GPUService()
    @ObservationIgnored private let memory = MemoryService()
    @ObservationIgnored private let process = ProcessService()
    @ObservationIgnored private let temperature = TemperatureService()
    @ObservationIgnored private let power = PowerService()
    @ObservationIgnored private let battery = BatteryService()
    @ObservationIgnored private let display = DisplayService()
    @ObservationIgnored private var latestGPUFrame: (ms: Double, at: Date)?
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

    /// Marks this moment in the CSV (e.g. "boss fight starts").
    func addMarker() {
        let number = (lastMarker?.number ?? 0) + 1
        lastMarker = (number, Date())
        pendingMarker = number
    }

    /// Output lines from a game started by `redline run` (Apple HUD lines carry GPU time per frame).
    func receiveGameOutput(_ line: String) {
        if let gpuMS = HUDFrameReport.parse(line)?.medianGPUTimeMS { latestGPUFrame = (gpuMS, Date()) }
    }

    private func refresh() {
        // Hook FPS (games run via `redline run`) is exact and uncapped; HUD log covers every other game.
        let currentFPS = fps.fps() ?? hudFPS.fps()
        let gameID = launchedGameID ?? hudFPS.processID
        stats = SystemStats(
            fps: currentFPS,
            pacing: frameTiming.sample(),
            gpuFrameMS: latestGPUFrame.flatMap { Date().timeIntervalSince($0.at) < 2 ? $0.ms : nil },
            displayHz: display.refreshRate(),
            cpuUsage: cpu.usage(),
            gpuUsage: gpu.usage(),
            memoryUsedGB: memory.usedGB(),
            memoryTotalGB: memory.totalGB,
            memoryPressure: memory.pressure(),
            swapUsedGB: memory.swapUsedGB(),
            game: gameID.flatMap { process.stats(for: $0) },
            cpuTemperature: temperature.cpu(),
            gpuTemperature: temperature.gpu(),
            socTemperature: temperature.soc(),
            power: power.sample(),
            battery: battery.status(),
            thermalState: ProcessInfo.processInfo.thermalState,
            marker: pendingMarker
        )
        pendingMarker = nil
        fpsHistory.append(currentFPS)
        onUpdate?(stats)
    }
}
