# ClipboardManager

A lightweight macOS **menu bar** clipboard history utility. It keeps the last 15
text clips you copy, so you can paste back something older than the single item
macOS retains natively.

- Lives only in the menu bar (no Dock icon).
- Captures plain-text clips automatically as you copy them anywhere.
- Click a clip → it becomes the current clipboard, ready to paste with ⌘V.
- Skips passwords / secrets flagged by password managers (1Password, Apple
  Passwords, etc.) via the [nspasteboard.org](http://nspasteboard.org) convention.
- History is in-memory only — it clears when the app quits.

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

- Click the clipboard icon in the menu bar to see recent clips (newest first).
- Click a clip to copy it back, then paste with ⌘V.
- **Clear** wipes the history; **Quit** exits the app.

## Architecture

A single SwiftUI app target, `LSUIElement = YES` (menu-bar-only):

- `PasteboardWatcher` — polls `NSPasteboard.general.changeCount` every 0.4s
  (macOS has no clipboard-change event) and captures new text clips, filtering
  out our own writes and concealed secrets.
- `ClipboardStore` — in-memory history (most-recent first, capped at 15), with
  duplicate suppression.
- `HistoryView` — the `MenuBarExtra` dropdown UI.

History is intentionally not persisted across restarts in this version.
