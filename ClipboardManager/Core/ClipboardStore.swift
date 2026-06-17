import AppKit
import Combine

/// In-memory + on-disk history of clips. Pinned items sort to the top and are
/// exempt from the rolling cap.
@MainActor
final class ClipboardStore: ObservableObject {
    /// Cap applies to *unpinned* clips; pinned ones are never auto-evicted.
    static let historyCap = 15

    /// Live instance, so App Intents (which the system instantiates) can reach
    /// the running app's history.
    static private(set) var shared: ClipboardStore?

    @Published private(set) var items: [ClipItem] = []

    /// Guards so the watcher ignores our own pasteboard writes (§7.2).
    private(set) var lastWrittenChangeCount: Int = -1
    private(set) var lastWrittenText: String?

    private let saveURL: URL?

    init() {
        saveURL = Self.makeSaveURL()
        load()
        Self.shared = self
    }

    // MARK: - Display / search

    /// Pinned first (recency within group), then unpinned (recency within group).
    var displayItems: [ClipItem] {
        items.filter(\.isPinned) + items.filter { !$0.isPinned }
    }

    func filteredDisplayItems(matching query: String) -> [ClipItem] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return displayItems }
        return displayItems.filter { $0.text.range(of: q, options: .caseInsensitive) != nil }
    }

    // MARK: - Mutations

    /// Capture a clip from a system copy. An identical existing clip is moved to
    /// the top (keeping its pin) rather than duplicated (§7.4).
    func add(_ text: String) {
        if let idx = items.firstIndex(where: { $0.text == text }) {
            let existing = items.remove(at: idx)
            items.insert(existing, at: 0)
        } else {
            items.insert(ClipItem(text: text), at: 0)
        }
        enforceCap()
        save()
    }

    /// User picked a clip: move it to the top and put it on the system clipboard.
    func select(_ item: ClipItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            let it = items.remove(at: idx)
            items.insert(it, at: 0)
        }
        writeToPasteboard(item.text)
        save()
    }

    func togglePin(_ item: ClipItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isPinned.toggle()
        enforceCap()
        save()
    }

    /// Clears unpinned clips; pinned favorites are kept.
    func clear() {
        items.removeAll { !$0.isPinned }
        save()
    }

    private func enforceCap() {
        var unpinned = items.lazy.filter { !$0.isPinned }.count
        guard unpinned > Self.historyCap else { return }
        for i in stride(from: items.count - 1, through: 0, by: -1) where unpinned > Self.historyCap {
            if !items[i].isPinned {
                items.remove(at: i)
                unpinned -= 1
            }
        }
    }

    private func writeToPasteboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        lastWrittenChangeCount = pb.changeCount
        lastWrittenText = text
    }

    // MARK: - Persistence

    private static func makeSaveURL() -> URL? {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = appSupport.appendingPathComponent("com.tomasz.ClipboardManager", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }

    private func load() {
        guard let url = saveURL, let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ClipItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let url = saveURL, let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
