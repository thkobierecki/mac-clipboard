import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Global shortcut that opens the clipboard popup. Defaults to ⌘⇧V; the user
    /// can rebind it in Settings.
    static let toggleClipboard = Self("toggleClipboard", default: .init(.v, modifiers: [.command, .shift]))
}
