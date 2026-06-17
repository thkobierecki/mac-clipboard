# ClipboardManager

A lightweight macOS **menu bar** clipboard history utility. It keeps your recent
text clips so you can paste back something older than the single item macOS
retains natively.

- Lives only in the menu bar (no Dock icon).
- Captures plain-text clips automatically as you copy them anywhere.
- **Global hotkey** (⌘⇧V) opens the popup from any app.
- **Search-as-you-type** to filter, **arrow keys + Enter** to pick, **⌘1–9** to
  grab a recent clip instantly.
- **Paste directly** into the active app (optional; needs Accessibility), or just
  copy the clip and paste with ⌘V yourself.
- **Pin favorites** so they stick to the top and survive the rolling cap.
- **Persistent history** — clips are saved to disk and restored on next launch.
- Skips passwords / secrets flagged by password managers (1Password, Apple
  Passwords, etc.) via the [nspasteboard.org](http://nspasteboard.org) convention.

Unpinned history is capped at 15 items (oldest dropped). Pinned items are never
auto-evicted.

## Requirements

- macOS 14 or later
- Xcode 15 or later (to build it)

## Build & install

1. Clone the repo:
   ```sh
   git clone https://github.com/thkobierecki/mac-clipboard.git
   cd mac-clipboard
   ```
2. Open the project:
   ```sh
   open ClipboardManager.xcodeproj
   ```
3. In Xcode, select the **ClipboardManager** scheme and press **⌘R** to build and run.
   A clipboard icon appears in the menu bar.

### Signing note

To run on another Mac (and for **Launch at login** to work reliably), set a
signing team in Xcode:

1. Select the project → **ClipboardManager** target → **Signing & Capabilities**.
2. Set **Team** to your Apple ID (free Apple IDs work for personal use).

Without a team the app still builds and runs locally with ad-hoc signing, but the
launch-at-login toggle may not persist.

### Installing it permanently

After building, the app is in Xcode's Derived Data. To keep it around:

1. In Xcode: **Product → Show Build Folder in Finder**, open `Products/Debug`.
2. Drag **ClipboardManager.app** into `/Applications`.
3. Launch it from Applications; optionally tick **Launch at login** in its menu.

## Usage

- Open the popup: click the menu bar icon, or press **⌘⇧V** from anywhere.
- **Type** to filter, **↑/↓** to move, **Enter** to pick, **⌘1–9** for a quick pick.
- **Pin** a clip with the pin icon (appears on hover/selection) to keep it at the top.
- **Paste to active app** (footer checkbox) pastes the chosen clip straight into
  whatever app you were in. Leave it off to just put the clip on the clipboard
  and paste with ⌘V yourself.
- **Clear** removes unpinned clips; **Quit** exits the app.

### Accessibility permission (for direct paste)

The first time you select a clip with **Paste to active app** enabled, macOS
prompts for Accessibility access (System Settings → Privacy & Security →
Accessibility). Grant it so the app can simulate ⌘V. The clip is on the clipboard
regardless, so manual ⌘V always works.

> Rebuilding the app changes its signature and can reset the Accessibility grant.
> A stable signed build (set a Team in Signing & Capabilities) avoids re-granting.

### Rebinding the hotkey

The global hotkey is ⌘⇧V, defined in
[`PanelController.setupHotKey()`](ClipboardManager/Core/PanelController.swift) —
change the `keyCode` / `modifiers` there.

## Where history is stored

`~/Library/Application Support/com.tomasz.ClipboardManager/history.json`
(plain JSON). Delete this file to wipe persisted history.

## Architecture

A single SwiftUI app target, `LSUIElement = YES` (menu-bar-only). The UI is a
custom `NSStatusItem` + floating `NSPanel` (not `MenuBarExtra`) so it can be
opened by a global hotkey and host a focused search field.

- `PasteboardWatcher` — polls `NSPasteboard.general.changeCount` every 0.4s
  (macOS has no clipboard-change event) and captures new text clips, filtering
  out our own writes and concealed secrets.
- `ClipboardStore` — history (most-recent first, unpinned capped at 15), with
  duplicate suppression, pinning, and JSON persistence.
- `PanelController` — status item, popup panel, global hotkey, keyboard
  navigation, and direct paste.
- `HistoryView` — the popup UI (search, list, pins, footer).
- `GlobalHotKey` / `Paster` — Carbon hotkey registration and synthesized ⌘V.
