import SwiftUI

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The main UI lives in a custom NSPanel managed by PanelController. The
        // Settings scene hosts the hotkey recorder, opened from the popup footer.
        Settings { SettingsView() }
    }
}

/// Owns the long-lived objects: store, pasteboard watcher, and the panel
/// controller (status item + popup + hotkey).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ClipboardStore()
    let menuState = MenuState()
    let launchAtLogin = LaunchAtLogin()

    private lazy var watcher = PasteboardWatcher(store: store)
    private var panelController: PanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        panelController = PanelController(store: store, menuState: menuState, launchAtLogin: launchAtLogin)
        watcher.start()
    }
}
