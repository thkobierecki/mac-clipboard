import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var menuState: MenuState
    @ObservedObject var launchAtLogin: LaunchAtLogin
    var onSelect: (ClipItem) -> Void

    @FocusState private var searchFocused: Bool

    private static let listHeight: CGFloat = 320

    private var filtered: [ClipItem] {
        store.filteredDisplayItems(matching: menuState.searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            listArea
            Divider()
            footer
        }
        .frame(width: 320)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onAppear { searchFocused = true }
        .onChange(of: menuState.isVisible) { _, visible in if visible { searchFocused = true } }
        .onChange(of: menuState.searchText) { _, _ in menuState.selectedIndex = 0 }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search", text: $menuState.searchText)
                .textFieldStyle(.plain)
                .focused($searchFocused)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var listArea: some View {
        if filtered.isEmpty {
            Text(store.items.isEmpty ? "No clips yet — copy something." : "No matches")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: Self.listHeight)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, item in
                            row(item: item, index: index)
                                .id(item.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: Self.listHeight)
                .onChange(of: menuState.selectedIndex) { _, i in
                    if filtered.indices.contains(i) {
                        proxy.scrollTo(filtered[i].id, anchor: .center)
                    }
                }
            }
        }
    }

    private func row(item: ClipItem, index: Int) -> some View {
        let isSelected = index == menuState.selectedIndex
        return HStack(spacing: 8) {
            Text(index < 9 ? "\(index + 1)" : " ")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .frame(width: 12, alignment: .trailing)

            Text(item.preview)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            Button {
                store.togglePin(item)
            } label: {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
            }
            .buttonStyle(.plain)
            .foregroundStyle(item.isPinned ? Color.accentColor : .secondary)
            .opacity(item.isPinned || isSelected ? 1 : 0)
            .help(item.isPinned ? "Unpin" : "Pin")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color.accentColor.opacity(0.20) : .clear)
                .padding(.horizontal, 6)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect(item) }
        .onHover { if $0 { menuState.selectedIndex = index } }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Toggle("Paste to active app", isOn: $menuState.autoPaste)
                .toggleStyle(.checkbox)
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("Launch at login", isOn: $launchAtLogin.isEnabled)
                .toggleStyle(.checkbox)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text("\(store.items.count) clip\(store.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear", action: store.clear)
                    .disabled(store.items.allSatisfy(\.isPinned))
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
