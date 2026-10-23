import SwiftUI

/// Developer section (preview): installs the `redline` Terminal command, or shows how to use it once installed.
struct TerminalCommandRow: View {
    @State private var isInstalled = CommandLineInstaller.isInstalled
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("Developer")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("PREVIEW")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.orange.opacity(0.15), in: Capsule())
                    .help("Still being tested. Please report anything that doesn't work.")
            }
            .padding(.bottom, 2)
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
                .help("Adds `redline` to Terminal so you can launch your own builds with frame-by-frame FPS")
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
