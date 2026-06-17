import AppKit
import Combine

/// In-memory history of clips (most-recent first). The only writer from system
/// copies is `PasteboardWatcher`; the view writes back via `select(_:)`.
@MainActor
final class ClipboardStore: ObservableObject {
    /// History cap — oldest entries are dropped past this (A1, confirmed = 15).
    static let historyCap = 15

    @Published private(set) var items: [ClipItem] = []

    /// `changeCount` produced by our own pasteboard writes. The watcher compares
    /// against this to avoid re-capturing a clip we just put back (§7.2).
    private(set) var lastWrittenChangeCount: Int = -1

    /// The exact string of our last self-write — a belt-and-suspenders second
    /// guard in case another app writes between `select()` and the next poll.
    private(set) var lastWrittenText: String?

    /// Capture a clip from a system copy. Suppresses an immediate duplicate of
    /// the current top item (§7.4) and trims to the cap.
    func add(_ text: String) {
        if items.first?.text == text { return }
        items.insert(ClipItem(text: text), at: 0)
        if items.count > Self.historyCap {
            items.removeLast(items.count - Self.historyCap)
        }
    }

    /// User picked a clip: move it to the top and make it the system clipboard.
    func select(_ item: ClipItem) {
        if let idx = items.firstIndex(of: item), idx != 0 {
            items.remove(at: idx)
            items.insert(item, at: 0)
        }
        writeToPasteboard(item.text)
    }

    func clear() {
        items.removeAll()
    }

    private func writeToPasteboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        lastWrittenChangeCount = pb.changeCount
        lastWrittenText = text
    }
}
