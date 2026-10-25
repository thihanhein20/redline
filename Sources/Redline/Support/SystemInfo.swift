import Foundation

/// App and Mac details attached to bug reports.
enum SystemInfo {
    static let appVersion = "0.2.0"
    /// Shown next to the version while Redline is in public beta; set to nil for a stable release.
    static let releaseStage: String? = "beta"

    /// "0.2.0 beta" during the beta, "0.2.0" once stable.
    static var displayVersion: String {
        [appVersion, releaseStage].compactMap { $0 }.joined(separator: " ")
    }

    static var summary: String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let macOS = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        return "Redline \(displayVersion) · macOS \(macOS) · \(sysctl("machdep.cpu.brand_string")) (\(sysctl("hw.model")))"
    }

    private static func sysctl(_ name: String) -> String {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return "unknown" }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return "unknown" }
        return String(decoding: buffer.prefix { $0 != 0 }.map(UInt8.init), as: UTF8.self)
    }
}
