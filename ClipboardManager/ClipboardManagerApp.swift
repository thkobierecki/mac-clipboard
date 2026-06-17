import SwiftUI

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Clipboard", systemImage: "doc.on.clipboard") {
            HistoryView(store: appDelegate.store, launchAtLogin: appDelegate.launchAtLogin)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Owns the store + watcher so polling starts at launch (not lazily when the
/// menu is first opened) and lives for the whole app lifetime.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ClipboardStore()
    let launchAtLogin = LaunchAtLogin()
    private lazy var watcher = PasteboardWatcher(store: store)

    func applicationDidFinishLaunching(_ notification: Notification) {
        watcher.start()
    }
}
