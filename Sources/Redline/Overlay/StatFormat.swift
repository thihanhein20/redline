import Foundation

/// Turns raw readings into short overlay strings. "--" means no reading yet.
enum StatFormat {
    static let placeholder = "--"
    static let hotCelsius = 90.0

    static func percent(_ value: Double?) -> String {
        value.map { String(format: "%.0f%%", $0) } ?? placeholder
    }

    static func celsius(_ value: Double?) -> String {
        value.map { String(format: "%.0f°C", $0) } ?? placeholder
    }

    static func memory(used: Double?, total: Double) -> String {
        used.map { String(format: "%.1f/%.0f GB", $0, total) } ?? placeholder
    }

    static func isHot(_ celsius: Double?) -> Bool {
        (celsius ?? 0) >= hotCelsius
    }

    static func thermal(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: "OK"
        case .fair: "FAIR"
        case .serious: "HOT"
        case .critical: "CRITICAL"
        @unknown default: placeholder
        }
    }
}
