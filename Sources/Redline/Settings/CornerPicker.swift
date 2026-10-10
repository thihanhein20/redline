import SwiftUI

/// A miniature screen; click a corner to move the overlay there.
struct CornerPicker: View {
    @Binding var selection: OverlayCorner

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow { cell(.topLeft); cell(.topRight) }
            GridRow { cell(.bottomLeft); cell(.bottomRight) }
        }
        .frame(height: 124)
        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
        .animation(.snappy(duration: 0.2), value: selection)
    }

    private func cell(_ corner: OverlayCorner) -> some View {
        let isSelected = selection == corner
        return Button {
            selection = corner
        } label: {
            RoundedRectangle(cornerRadius: 3)
                .fill(isSelected ? Color.red : Color.secondary.opacity(0.25))
                .frame(width: isSelected ? 38 : 30, height: isSelected ? 24 : 18)
                .shadow(color: isSelected ? .red.opacity(0.4) : .clear, radius: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: corner.alignment)
                .padding(10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(corner.title)
        .accessibilityLabel(corner.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
