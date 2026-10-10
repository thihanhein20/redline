import SwiftUI

/// Developer section: installs the `redline` Terminal command, or shows how to use it once installed.
struct TerminalCommandRow: View {
    @State private var isInstalled = CommandLineInstaller.isInstalled
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isInstalled {
                Label("Terminal command installed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                Text("redline run ./Builds/MyGame.app")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .padding(.horizontal, 8)
            } else {
                MenuRow(title: "Install Terminal Command", systemImage: "terminal") {
                    message = CommandLineInstaller.install()
                    isInstalled = CommandLineInstaller.isInstalled
                }
                .help("Adds `redline` to Terminal so you can launch your own builds with exact FPS")
            }
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
            }
        }
    }
}
