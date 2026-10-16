import AppKit
import SwiftUI

/// Settings section: save every play session as a CSV + summary, and open the folder they're in.
struct RecordingRow: View {
    @Bindable var sessions: SessionRecorder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Record sessions", isOn: $sessions.savesToDisk)
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(.red)
                .font(.subheadline.weight(.medium))
                .help("Saves one CSV and a summary for every game you play. Starts with the next game.")
            Text("One CSV and summary per game, in Logs/Redline")
                .font(.caption)
                .foregroundStyle(.secondary)
            MenuRow(title: "Show Logs in Finder", systemImage: "folder") {
                try? FileManager.default.createDirectory(at: SessionLog.folder, withIntermediateDirectories: true)
                NSWorkspace.shared.open(SessionLog.folder)
            }
        }
    }
}
