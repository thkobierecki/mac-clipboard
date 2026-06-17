import AppKit
import Carbon
import SwiftUI

/// A borderless floating panel that can still become key (so the search field
/// accepts typing).
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Owns the menu bar status item and the popup panel, and wires up the global
/// hotkey, keyboard navigation, and direct-paste behavior.
@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    private let store: ClipboardStore
    private let menuState: MenuState
    private let launchAtLogin: LaunchAtLogin

    private var statusItem: NSStatusItem!
    private var panel: KeyablePanel!
    private var keyMonitor: Any?
    private var hotKey: GlobalHotKey?
    private weak var previousApp: NSRunningApplication?

    init(store: ClipboardStore, menuState: MenuState, launchAtLogin: LaunchAtLogin) {
        self.store = store
        self.menuState = menuState
        self.launchAtLogin = launchAtLogin
        super.init()
        setupStatusItem()
        setupPanel()
        setupHotKey()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
            button.action = #selector(toggle)
            button.target = self
        }
    }

    private func setupPanel() {
        let view = HistoryView(
            store: store,
            menuState: menuState,
            launchAtLogin: launchAtLogin,
            onSelect: { [weak self] in self?.activate($0) }
        )
        let hosting = NSHostingView(rootView: view)
        hosting.autoresizingMask = [.width, .height]

        panel = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: hosting.fittingSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.delegate = self
    }

    private func setupHotKey() {
        // ⌘⇧V — change keyCode/modifiers here to rebind.
        hotKey = GlobalHotKey(keyCode: 9, modifiers: UInt32(cmdKey | shiftKey)) { [weak self] in
            DispatchQueue.main.async { self?.toggle() }
        }
    }

    // MARK: - Show / hide

    @objc private func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        menuState.searchText = ""
        menuState.selectedIndex = 0

        if let hosting = panel.contentView {
            panel.setContentSize(hosting.fittingSize)
        }
        positionPanel()

        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        menuState.isVisible = true
        installKeyMonitor()
    }

    func hide() {
        removeKeyMonitor()
        menuState.isVisible = false
        panel.orderOut(nil)
    }

    private func positionPanel() {
        guard let button = statusItem.button, let buttonWindow = button.window else { return }
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        var x = buttonRect.midX - panel.frame.width / 2
        let y = buttonRect.minY - panel.frame.height - 4
        if let visible = buttonWindow.screen?.visibleFrame {
            x = min(max(x, visible.minX + 8), visible.maxX - panel.frame.width - 8)
        }
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Selection + paste

    private func activate(_ item: ClipItem) {
        store.select(item)
        let shouldPaste = menuState.autoPaste

        removeKeyMonitor()
        menuState.isVisible = false
        panel.orderOut(nil)

        guard shouldPaste else { return }
        if Paster.isTrusted {
            previousApp?.activate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                Paster.paste()
            }
        } else {
            // First time: guide the user to grant Accessibility. The clip is
            // already on the clipboard, so they can paste manually meanwhile.
            Paster.promptTrust()
        }
    }

    // MARK: - Keyboard navigation

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handleKey(event)
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    /// Returns `nil` to consume the event (navigation keys), or the event itself
    /// to let it fall through to the search field (typed characters).
    private func handleKey(_ event: NSEvent) -> NSEvent? {
        let items = store.filteredDisplayItems(matching: menuState.searchText)

        switch Int(event.keyCode) {
        case kVK_DownArrow:
            if !items.isEmpty { menuState.selectedIndex = min(menuState.selectedIndex + 1, items.count - 1) }
            return nil
        case kVK_UpArrow:
            if !items.isEmpty { menuState.selectedIndex = max(menuState.selectedIndex - 1, 0) }
            return nil
        case kVK_Return, kVK_ANSI_KeypadEnter:
            if items.indices.contains(menuState.selectedIndex) { activate(items[menuState.selectedIndex]) }
            return nil
        case kVK_Escape:
            hide()
            return nil
        default:
            if event.modifierFlags.contains(.command),
               let ch = event.charactersIgnoringModifiers, let n = Int(ch),
               (1...9).contains(n), items.indices.contains(n - 1) {
                activate(items[n - 1])
                return nil
            }
            return event
        }
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        if panel.isVisible { hide() } // click-away dismiss
    }
}
