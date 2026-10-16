import SwiftUI

/// The global shortcuts, as a reminder at the bottom of settings.
struct ShortcutList: View {
    private let shortcuts: [(title: String, shortcut: KeyShortcut)] = [
        ("Open settings", .toggleSettings),
        ("Show or hide overlay", .toggleOverlay),
        ("Add marker", .addMarker),
    ]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(shortcuts, id: \.title) { item in
                HStack {
                    Text(item.title)
                    Spacer()
                    Text(item.shortcut.symbol)
                        .font(.caption.monospaced())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
    }
}
