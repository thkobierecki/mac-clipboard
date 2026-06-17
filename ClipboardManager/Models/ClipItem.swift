import Foundation

/// One captured clip. Value type; `id` makes it usable directly in SwiftUI lists.
struct ClipItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let createdAt: Date

    init(text: String, createdAt: Date = Date()) {
        self.text = text
        self.createdAt = createdAt
    }

    /// Single-line, truncated rendering for the menu (A4). Full `text` is still
    /// what gets copied back on selection.
    var preview: String {
        let limit = 60
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            // Clip was only whitespace/newlines — show something rather than a blank row.
            return "⏎ (whitespace)"
        }
        if trimmed.count > limit {
            return trimmed.prefix(limit) + "…"
        }
        return trimmed
    }
}
