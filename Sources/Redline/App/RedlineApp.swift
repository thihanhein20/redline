import SwiftUI

@main
struct RedlineApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        LaunchArguments.compareIfRequested()
        RedlineInstances.exitIfDuplicate()
    }

    var body: some Scene {
        // A headless `redline run` leaves the menu bar icon to the Redline that's already open.
        MenuBarExtra("Redline", systemImage: "gauge.with.dots.needle.67percent", isInserted: .constant(!RedlineInstances.isHeadless)) {
            SettingsView(overlay: appDelegate.overlay, sessions: appDelegate.sessions)
        }
        .menuBarExtraStyle(.window)
    }
}
