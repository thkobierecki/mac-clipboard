import AppIntents

/// Copies one of the recent clips back onto the system clipboard.
struct CopyRecentClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Copy Recent Clip"
    static let description = IntentDescription("Copies one of your recent clipboard clips back onto the clipboard.")

    @Parameter(title: "Position (1 = most recent)", default: 1)
    var position: Int

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let items = ClipboardStore.shared?.displayItems ?? []
        guard items.indices.contains(position - 1) else {
            throw IntentError.noClip(position)
        }
        let item = items[position - 1]
        ClipboardStore.shared?.select(item)
        return .result(value: item.text)
    }
}

/// Returns the text of the most recent clip without changing the clipboard.
struct GetLatestClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Latest Clip"
    static let description = IntentDescription("Returns the text of your most recent clip.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: ClipboardStore.shared?.displayItems.first?.text ?? "")
    }
}

/// Clears unpinned clips from history.
struct ClearClipboardHistoryIntent: AppIntent {
    static let title: LocalizedStringResource = "Clear Clipboard History"
    static let description = IntentDescription("Removes all unpinned clips from history.")

    @MainActor
    func perform() async throws -> some IntentResult {
        ClipboardStore.shared?.clear()
        return .result()
    }
}

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case noClip(Int)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noClip(let n): "There is no clip at position \(n)."
        }
    }
}

struct ClipboardShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetLatestClipIntent(),
            phrases: ["Get latest clip from \(.applicationName)"],
            shortTitle: "Latest Clip",
            systemImageName: "doc.on.clipboard"
        )
        AppShortcut(
            intent: ClearClipboardHistoryIntent(),
            phrases: ["Clear \(.applicationName) history"],
            shortTitle: "Clear History",
            systemImageName: "trash"
        )
    }
}
