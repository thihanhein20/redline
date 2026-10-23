import SwiftUI

/// Redline's settings: shown from the menu bar icon and in the settings window.
struct SettingsView: View {
    @Bindable var overlay: OverlayController
    let sessions: SessionRecorder
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Overlay Position")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                CornerPicker(selection: $overlay.corner)
                Picker("Detail", selection: $overlay.detail) {
                    ForEach(OverlayDetail.allCases, id: \.self) { Text($0.title) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .help("Compact: FPS, CPU, GPU, temperature. Full: everything Redline measures.")
            }
            .disabled(!overlay.isVisible)
            .opacity(overlay.isVisible ? 1 : 0.4)
            Divider()

            RecordingRow(sessions: sessions)
            Divider()

            if let last = sessions.last {
                LastSessionView(summary: last)
                Divider()
            }

            VStack(spacing: 2) {
                MenuRow(title: "Send Feedback", systemImage: "bubble.left") { openURL(FeedbackLinks.sendFeedback) }
                MenuRow(title: "Report an Issue", systemImage: "ladybug") { openURL(FeedbackLinks.reportIssue) }
            }
            Divider()

            TerminalCommandRow()
            Divider()

            MenuRow(title: "Quit Redline", systemImage: "power") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
            ShortcutList()
            Divider()
            credit
        }
        .padding(14)
        .frame(width: 270)
    }

    private var credit: some View {
        HStack(spacing: 4) {
            Text("Developed by")
            Link("Han Industries", destination: FeedbackLinks.developer)
                .tint(.red)
            Spacer()
            Text("v\(SystemInfo.appVersion)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.title2)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 1) {
                Text("Redline").font(.headline)
                Text("Performance overlay").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("Show overlay", isOn: $overlay.isVisible)
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
                .tint(.red)
                .help("Show or hide the overlay")
        }
    }
}
