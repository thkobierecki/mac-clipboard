import Foundation

/// One captured clip. Codable so the store can persist history to disk.
struct ClipItem: Identifiable, Equatable, Codable {
    let id: UUID
    let text: String
    let createdAt: Date
    var isPinned: Bool

    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isPinned = isPinned
    }

    /// Single-line, truncated rendering for the menu. Full `text` is what gets
    /// copied back on selection.
    var preview: String {
        let limit = 60
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            return "⏎ (whitespace)"
        }
        if trimmed.count > limit {
            return trimmed.prefix(limit) + "…"
        }
        return trimmed
    }
}
