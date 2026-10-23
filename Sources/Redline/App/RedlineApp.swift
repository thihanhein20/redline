import SwiftUI

@main
struct RedlineApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        LaunchArguments.compareIfRequested()
    }

    var body: some Scene {
        MenuBarExtra("Redline", systemImage: "gauge.with.dots.needle.67percent") {
            SettingsView(overlay: appDelegate.overlay, sessions: appDelegate.sessions)
        }
        .menuBarExtraStyle(.window)
    }
}
