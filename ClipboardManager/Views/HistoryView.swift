import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var launchAtLogin: LaunchAtLogin
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if store.items.isEmpty {
                emptyState
            } else {
                clipList
            }
            Divider()
            footer
        }
        .frame(width: 320)
    }

    private var emptyState: some View {
        Text("No clips yet — copy something.")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 12)
    }

    /// Approx. height of one rendered row (text + vertical padding).
    private static let rowHeight: CGFloat = 30

    private var clipList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(store.items) { item in
                    Button {
                        store.select(item)
                        dismiss()
                    } label: {
                        Text(item.preview)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .buttonStyle(ClipRowButtonStyle())
                }
            }
            .padding(.vertical, 4)
        }
        // Explicit height: a ScrollView inside a size-to-fit MenuBarExtra window
        // collapses to ~zero otherwise. Grow with the item count, cap at 360.
        .frame(height: min(CGFloat(store.items.count) * Self.rowHeight + 8, 360))
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Toggle("Launch at login", isOn: $launchAtLogin.isEnabled)
                .toggleStyle(.checkbox)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text("\(store.items.count) clip\(store.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear", action: store.clear)
                    .disabled(store.items.isEmpty)
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// Menu-style row: full-width hit target with a hover highlight.
private struct ClipRowButtonStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(hovering ? Color.accentColor.opacity(0.18) : .clear)
                    .padding(.horizontal, 6)
            )
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
    }
}
