import SwiftUI

/// UI state for the popup, shared between the SwiftUI view and the panel
/// controller (which drives keyboard navigation from a local event monitor).
@MainActor
final class MenuState: ObservableObject {
    @Published var searchText = ""
    @Published var selectedIndex = 0
    @Published var isVisible = false

    /// When on, selecting a clip pastes it straight into the frontmost app
    /// (requires Accessibility permission). Persisted across launches.
    @Published var autoPaste: Bool {
        didSet { UserDefaults.standard.set(autoPaste, forKey: Self.autoPasteKey) }
    }

    private static let autoPasteKey = "autoPaste"

    init() {
        autoPaste = UserDefaults.standard.object(forKey: Self.autoPasteKey) as? Bool ?? true
    }
}
