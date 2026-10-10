import Foundation

/// One snapshot of everything Redline measures. `nil` means "not available yet".
struct SystemStats {
    var fps: Double?
    var cpuUsage: Double?
    var gpuUsage: Double?
    var memoryUsedGB: Double?
    var memoryTotalGB: Double = 0
    var socTemperature: Double?
    var thermalState: ProcessInfo.ThermalState = .nominal
}
