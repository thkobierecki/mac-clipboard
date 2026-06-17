import ServiceManagement

/// Wraps `SMAppService.mainApp` registration as a bindable toggle (milestone 7).
///
/// Note: registration requires the app to be a bundled, signed `.app`. When run
/// unsigned straight from Xcode, `register()` may throw — we surface that by
/// snapping the toggle back to the real service status rather than crashing.
@MainActor
final class LaunchAtLogin: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            let alreadyMatches = (SMAppService.mainApp.status == .enabled) == isEnabled
            guard !alreadyMatches else { return }
            do {
                if isEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Revert to whatever the system actually reports.
                isEnabled = SMAppService.mainApp.status == .enabled
            }
        }
    }

    init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
}
