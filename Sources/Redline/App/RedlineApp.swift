import SwiftUI

@main
struct RedlineApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Redline", systemImage: "gauge.with.dots.needle.67percent") {
            MenuBarView(overlay: appDelegate.overlay)
        }
        .menuBarExtraStyle(.window)
    }
}
