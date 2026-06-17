import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Open clipboard popup:", name: .toggleClipboard)
            } footer: {
                Text("Press this shortcut from any app to open the clipboard list.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 150)
    }
}
