import Foundation

/// Saves one play session to disk: a CSV (one row per second) and, when it ends, a summary .txt next to it.
final class SessionLog {
    /// No permission prompt needed here, unlike Documents or Desktop.
    static let folder = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/Redline")

    let csvURL: URL
    private let handle: FileHandle

    init?(game: String?, startedAt: Date, folder: URL = SessionLog.folder) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        csvURL = folder.appendingPathComponent(Self.baseName(game: game, startedAt: startedAt) + ".csv")
        guard FileManager.default.createFile(atPath: csvURL.path, contents: Data((CSVLogger.header + "\n").utf8)),
              let handle = try? FileHandle(forWritingTo: csvURL) else { return nil }
        handle.seekToEndOfFile()
        self.handle = handle
    }

    func append(_ stats: SystemStats, at date: Date = .now) {
        handle.write(Data((CSVLogger.row(for: stats, at: date) + "\n").utf8))
    }

    /// Closes the CSV and writes the summary next to it.
    func finish(with summary: SessionSummary) {
        try? handle.close()
        let text = SessionReport.text(for: summary) + "\n"
        try? text.write(to: csvURL.deletingPathExtension().appendingPathExtension("txt"), atomically: true, encoding: .utf8)
    }

    /// Too short to keep: closes and deletes the CSV.
    func discard() {
        try? handle.close()
        try? FileManager.default.removeItem(at: csvURL)
    }

    /// "Crossy Road_2026-10-16_19-37-06": game name (without characters that break file names) and start time.
    static func baseName(game: String?, startedAt: Date) -> String {
        let name = (game ?? "Session").components(separatedBy: CharacterSet(charactersIn: "/:\\")).joined(separator: "-")
        let stamp = startedAt.formatted(.verbatim(
            "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)_\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased))-\(minute: .twoDigits)-\(second: .twoDigits)",
            timeZone: .current, calendar: .current))
        return "\(name)_\(stamp)"
    }
}
