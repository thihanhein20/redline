import Foundation

/// One `metal-HUD: <totalFrames>,...` line that Apple's Metal HUD writes to the system log every ~0.5 s,
/// as printed by `log stream --style ndjson`. Only the frame count is public; the rest is `<private>`.
struct HUDLogEntry: Equatable {
    static let messagePrefix = "metal-HUD:"

    let processID: Int32
    let time: Date
    let totalFrames: Int

    private struct Raw: Decodable {
        let processID: Int32
        let timestamp: String
        let eventMessage: String
    }

    private static let timestampFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"  // 2026-10-10 12:09:59.265541+1100
        return formatter
    }()

    static func parse(_ line: String) -> HUDLogEntry? {
        guard let raw = try? JSONDecoder().decode(Raw.self, from: Data(line.utf8)),
              raw.eventMessage.hasPrefix(messagePrefix),
              let time = timestampFormat.date(from: raw.timestamp),
              let framesField = raw.eventMessage.dropFirst(messagePrefix.count).split(separator: ",").first,
              let frames = Int(framesField.trimmingCharacters(in: .whitespaces))
        else { return nil }
        return HUDLogEntry(processID: raw.processID, time: time, totalFrames: frames)
    }

    static func fps(from old: HUDLogEntry, to new: HUDLogEntry) -> Double? {
        let seconds = new.time.timeIntervalSince(old.time)
        guard seconds > 0, new.totalFrames >= old.totalFrames else { return nil }
        return Double(new.totalFrames - old.totalFrames) / seconds
    }
}
