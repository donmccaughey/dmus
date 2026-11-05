# Move the macOS app from SwiftUI to programmatic AppKit

## Context

Dmus is a single multiplatform Xcode target (`dmus`, product `Dmus.app`) that
builds for macOS and iOS from one source folder, splitting platform code with
`#if os(...)`. All UI is SwiftUI today. The macOS app is to be rewritten with
AppKit classes created in code: no nibs, no storyboards, and no `NSHostingView`
or `import SwiftUI` in the finished macOS build. iOS stays SwiftUI. The model
layer (`MusicLibraryStore` in the app; `Player`, `Queue`, `MusicLibrary` and
the wrappers in `dmusBase`) is UI-free and is reused unchanged.

The macOS UI is small: a main window with two equal panels (files tree left,
queue with player controls right), drag and drop from the tree to the queue, a
Settings window with one setting, and a "Settings…" menu item. Everything
SwiftUI provided implicitly on macOS (menu bar, window creation, size
persistence, observation-driven redraws) must now be written explicitly, so
those are the main new pieces of work.

## Decisions

- **Incremental, always launchable.** Step 2 installs the AppKit app shell
  (delegate, menu bar, window) and temporarily hosts the existing SwiftUI
  `MainView` and `SettingsView` in `NSHostingView`. Later steps replace one
  panel at a time, wrapping each replaced SwiftUI file in `#if os(iOS)` in the
  same step so nothing dangles. The last step removes the scaffolding. Each
  step builds for both platforms and is verified with the `launch-mac-app`
  skill.
- **Observation bridge.** AppKit on macOS 15 has no automatic observation
  tracking. A small `observeChanges { }` helper built on
  `withObservationTracking(_:onChange:)` re-runs a closure on the main actor
  whenever an `@Observable` property it read changes. `onChange` fires in
  `willSet` and is one-shot, so the re-run is scheduled with
  `Task { @MainActor in … }` and re-registers itself. Views capture `self`
  weakly; when a view is gone the closure reads nothing and the chain ends.
  Never read `player.timeIndex` in an `observeChanges` block (it updates many times a
  second); nothing in the UI needs it.
- **Window size persistence** uses `setFrameAutosaveName("main")` with
  `isRestorable = false` (key `NSWindow Frame main` in the container plist)
  instead of NSWindow state restoration. Closing the main window terminates
  the app from `windowWillClose`; this is the only quit-on-close path.
- **Menu bar**: App (About, Settings… ⌘, , Services, Hide ⌘H, Hide Others
  ⌥⌘H, Show All, Quit ⌘Q), File (Close ⌘W), Edit (Undo, Redo, Cut, Copy,
  Paste, Delete, Select All; needed for copying from the read-only path field),
  Window (Minimize ⌘M, Zoom, Bring All to Front; set as `NSApp.windowsMenu`).
  The View (Enter Full Screen) and Help menus SwiftUI added are dropped; the
  requirements doc records the menu set.
- **Panels are fixed equal halves**, matching the current non-resizable
  SwiftUI layout. An `NSSplitView` is an easy later change if resizing is
  wanted.
- **Naming.** AppKit types take AppKit conventional names
  (`MainWindowController`, `FilesPanelViewController`, `PlayerPanelView`,
  `QueuedTrackCellView`, `EmptyStateView` …) that never collide with the iOS
  SwiftUI structs (`FilesPanel`, `PlayerPanel`, `QueuedTrackRow`) or with
  SwiftUI's own `ContentUnavailableView`, which interim builds still compile
  for macOS. Files stay organized by feature (`dmus/files/`, `dmus/queue/`,
  `dmus/settings/`) per `docs/requirements.md`.
- **Drag payload** keeps the exported UTI `cc.donm.dmus.folder-child` already
  declared in `dmus/Info.plist`, carrying JSON of `FolderChild` (`Codable`).
  The `Transferable` conformance is deleted once nothing uses it.
- **Testable logic is extracted** into platform-neutral pure code and tested
  in `dmusTests` the way `MusicLibraryStore` is (membership exceptions in
  `project.pbxproj`). `make check` runs `dmusTests` on the iOS simulator too,
  so a shared file is either whole-file `#if os(macOS)` or platform-neutral.
- **Previews.** `#Preview` is kept for AppKit views and controllers with the
  existing sample data; those files `import DeveloperToolsSupport` (which
  declares the macro), never SwiftUI.
- **Layout details carried over from the review:** `NSStackView` uses
  `distribution = .fill` with explicit equal-width (or equal-height)
  constraints, because `.fillEqually` would also equalize the 1pt separator.
  Single-column tables set `columnAutoresizingStyle = .uniformColumnAutoresizingStyle`
  and the outline view sets `outlineTableColumn`, or cells clip at the default
  column width and no disclosure triangles appear.

## Files

### Shared app infrastructure (`dmus/`)

| File | Change |
|---|---|
| `dmusApp.swift` | Becomes iOS-only: `#if os(iOS)` around `@main struct DmusApp: App` with the `WindowGroup`. Remove `DmusAppDelegate` and the `Window`/`Settings` scenes. (Two `@main` declarations in mutually exclusive `#if os` branches compile fine.) |
| `DmusAppDelegate.swift` (new, macOS) | `@main final class DmusAppDelegate: NSObject, NSApplicationDelegate`. Owns `store`, `player`, `MainWindowController`, `SettingsWindowController`. `applicationWillFinishLaunching`: `NSWindow.allowsAutomaticWindowTabbing = false`, `NSApp.mainMenu = MainMenu.make(...)`. `applicationDidFinishLaunching`: `store.loadInBackground(isDemo: CommandLine.arguments.contains("--demo"))`, `mainWindowController.showWindow(nil)`. `applicationSupportsSecureRestorableState` returns true (avoids a warning on every launch that would land in the skill's stderr log). `@objc func showSettings(_:)`. Supplies its own `static func main()` that creates the delegate, assigns `NSApp.delegate` and calls `NSApplicationMain`: the `main()` AppKit provides for a `@main` delegate only calls `NSApplicationMain` and relies on a nib to instantiate the delegate, so without it no delegate callback ever runs and no window appears. No `NSPrincipalClass` key is needed. |
| `MainMenu.swift` (new, macOS) | `enum MainMenu { static func make(settingsTarget: AnyObject, settingsAction: Selector) -> NSMenu }` building the four menus with standard first-responder selectors (`orderFrontStandardAboutPanel:`, `hide:`, `hideOtherApplications:` with `[.command, .option]`, `unhideAllApplications:`, `terminate:`, `performClose:`, `undo:`, `redo:`, `cut:`, `copy:`, `paste:`, `delete:`, `selectAll:`, `performMiniaturize:`, `performZoom:`, `arrangeInFront:`). Sets `NSApp.servicesMenu` and `NSApp.windowsMenu`. Edit selectors with a nil target reach the field editor of the selectable path field, so ⌘A/⌘C work there. |
| `MainWindowController.swift` (new, macOS) | `NSWindow(contentRect: 0,0,900,600, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)`, title "Dmus", `tabbingMode = .disallowed`, `isRestorable = false`. Order matters: assign `contentViewController` (whose `loadView` creates a 900×600 view) first, then `center()`, then `super.init(window:)`, then `shouldCascadeWindows = false` and `windowFrameAutosaveName = "main"` on the controller, which restores a saved frame if one exists. (`NSWindowController` resets the window's own autosave name when it takes the window, so `window.setFrameAutosaveName` before `super.init` is silently lost.) The minimum size lives in `MainViewController` as `>= 640` / `>= 480` constraints on its view: once a window has a content view controller it derives its minimum from the content constraints and ignores `contentMinSize`. As `NSWindowDelegate`, `windowWillClose` calls `NSApp.terminate(nil)`. |
| `MainViewController.swift` (new, macOS) | Overrides `loadView()` without calling super (so AppKit never looks for a nib) and builds a horizontal `NSStackView` (spacing 0, `.fill`) of `FilesPanelViewController.view`, a vertical `NSBox` separator with `widthAnchor == 1`, `QueuePanelViewController.view`, plus `files.widthAnchor == queue.widthAnchor`. Adds the two as child view controllers. |
| `PanelView.swift` (new, macOS) | Replaces `Panel` on macOS: title bar (`NSVisualEffectView`, material `.headerView`, `.withinWindow`; `.titlebar` renders visibly darker than SwiftUI's `.bar`, `.headerView` matches it) holding a centered `NSFont.preferredFont(forTextStyle: .headline)` label with 16pt vertical padding and an optional accessory view pinned trailing with an 8pt inset; a horizontal `NSBox` separator (`heightAnchor == 1`, which is not optional: a separator box picks its orientation from its frame, so without the constraint and with content that has no intrinsic size the solver made the separator 552pt tall and the content zero); a content slot filling the rest. API: `init(title:accessory:)`, `func setContent(_ view: NSView)` (replaces the current content view, if different). `NSView+FillingSubview.swift` holds the shared `addFillingSubview(_:)` used here and by `DropTargetView`. |
| `EmptyStateView.swift` (new, macOS) | AppKit stand-in for SwiftUI's `ContentUnavailableView`: SF Symbol at point size 36 (`NSImage(systemSymbolName:)`, secondary tint), bold title at the large-title size (26pt), body description in the secondary color, centered; 24pt below the symbol and 12pt between the labels. Those values were measured against the SwiftUI screenshots in step 7 (the first cut used a 44pt symbol and a title2 title and looked visibly different). `var descriptionText: String` so the files panel can switch between "did not load" and "is empty". |
| `Observing.swift` (new, platform-neutral, also in `dmusTests`) | `@MainActor func observeChanges(_ apply: @escaping @MainActor () -> Void)`: runs `apply` inside `withObservationTracking`; in `onChange` schedules `Task { @MainActor in observeChanges(apply) }`. Named `observeChanges` rather than `observe` because `NSObject` has an `observe(_:options:changeHandler:)` member, and inside an `NSView` subclass a member shadows a same-named global function. |
| `ObservingTests.swift` (new, `dmusTests` only) | An `@Observable` fixture; `observeChanges` copies a property into a counter; mutate; then poll `while runs < 2 { await Task.yield() }` with a bounded iteration count (ordering between the onChange task and the test continuation is not guaranteed); expect the second run saw the new value. Also: a closure that reads nothing is run once only. `@Test` methods are MainActor-isolated under the target's default isolation, so calling `observeChanges` from them is fine. |
| `Panel.swift`, `MainView.swift` | Wrap in `#if os(iOS)` and drop the `#if os(macOS)` branches inside (`.bar` material, side-by-side-only path). `MainView.swift` in step 4; `Panel.swift` in step 5, because the SwiftUI `QueuePanel` hosted through step 4 still uses it. |
| `Scene+ContentArea.swift` | Delete in step 2. `NSWindow(contentRect:)` is already in content-area terms. |

### Files panel (`dmus/files/`)

| File | Change |
|---|---|
| `FilesPanelViewController.swift` (new, macOS) | `loadView` builds a `PanelView(title: "Files", accessory: findButton)`. `findButton` is `NSButton(title: "Find", target: nil, action: nil)`, `bezelStyle = .push`, `controlSize = .regular`. Holds an `EmptyStateView("No music", systemImage: "folder")` and a `FilesTreeView`. One `observeChanges` block reads `store.library` and `store.loadDidFail`: picks the content view, sets the description text, sets `findButton.isEnabled`, and passes the library to the tree. |
| `FilesTreeNode.swift` (new, macOS) | `final class FilesTreeNode { let child: FolderChild; lazy var children: [FilesTreeNode] }`. NSOutlineView keys expansion state and drags on item identity, so folders and tracks need stable reference-type items rather than `FolderChild` enum values. Built once per library from `rootFolder.children`. |
| `FilesTreeView.swift` (new, macOS) | `NSScrollView` wrapping an `NSOutlineView`: one column assigned to `outlineTableColumn`, `headerView = nil`, `style = .inset`, `usesAlternatingRowBackgroundColors = false`, `columnAutoresizingStyle = .uniformColumnAutoresizingStyle`, `setDraggingSourceOperationMask(.copy, forLocal: true)`. A `FilesTreeDataSource: NSOutlineViewDataSource, NSOutlineViewDelegate` over `[FilesTreeNode]`: `child:ofItem:`, `isItemExpandable:` (folders only), `numberOfChildrenOfItem:`, `viewFor:item:` returning a reused `NSTableCellView` (identifier, `imageView` with `folder`/`music.note` symbol, `textField` with the name), `pasteboardWriterForItem:` returning `node.child.pasteboardItem()`. `func setLibrary(_:)` rebuilds the nodes and calls `reloadData()`. |
| `FolderChild+Pasteboard.swift` (new, whole file `#if os(macOS)`, also in `dmusTests`) | `nonisolated extension NSPasteboard.PasteboardType { static let folderChild = NSPasteboard.PasteboardType("cc.donm.dmus.folder-child") }`; `extension FolderChild { func pasteboardItem() -> NSPasteboardItem` (JSONEncoder data under that type); `init?(pasteboardItem:)` (JSONDecoder); `static func folderChildren(in pasteboard: NSPasteboard) -> [FolderChild] }`. |
| `FolderChild+PasteboardTests.swift` (new, `dmusTests`, whole file `#if os(macOS)`) | Round-trip a folder with nested children and a loose track; an item without the type yields nil. `NSPasteboardItem` works in-process in a host-less test bundle. |
| `FilesTree.swift` | Delete in step 4. |
| `FilesPanel.swift`, `FindButton.swift` | Wrap in `#if os(iOS)` in step 4; remove the macOS branches (`showsTitle`, `FilesTree`). `FilesTableStack.swift` is already iOS-only. |
| `FolderChild+Transferable.swift` | Keep through step 4 (SwiftUI's `CodableRepresentation` reads the same JSON under the same UTI, so AppKit drags drop onto the hosted SwiftUI queue in the interim); delete in step 5. |

### Queue panel (`dmus/queue/`)

| File | Change |
|---|---|
| `QueuePanelViewController.swift` (new, macOS) | `PanelView(title: "Queue", accessory: clearButton)`; clear button is a push `NSButton("Clear")` whose action calls `player.clear()`. Content is a `DropTargetView` (own file; an `NSView` subclass: `registerForDraggedTypes([.folderChild])`, `.copy` from `draggingEntered` (AppKit reuses that answer for `draggingUpdated`), `performDragOperation` decodes `FolderChild.folderChildren(in:)` and calls `onDrop`) that shows either `EmptyStateView("No tracks", systemImage: "list.bullet", description: "The queue is empty.")` or a vertical `.fill` `NSStackView` of `PlayerPanelView`, a 1pt separator, and `QueueTableView` (low vertical hugging). One `observeChanges` block reads `player.queue.queuedTracks`, enables the clear button, swaps the content (a no-op when unchanged, so the table and scroll position survive adds) and then hands the tracks to the table; a single block keeps the swap ahead of the table's scroll-to-end on the first drop. Drop closure: `player.queue.add(children)`. The inner scroll/table views register no drag types, so drops land on the enclosing view. |
| `PlayerPanelView.swift` (new, macOS) | Horizontal centered `NSStackView` of three push `NSButton`s with symbol images only (`backward.fill`, `play.fill`/`stop.fill`, `forward.fill`), width constraints 60 / 72 / 60 (SwiftUI's 44pt label frame plus its bezel padding came to about 60pt on screen; constraining the whole button keeps the 20% ratio exact), 16pt padding all round, fixed intrinsic height. Buttons carry `setAccessibilityTitle` ("Back", "Play"/"Stop", "Next") so System Events `click button "Play"` works. `observeChanges` reads `player.isPlaying` and `player.queue.isEmpty` to swap the play/stop image and accessibility title ("Play"/"Stop") and set `isEnabled` on all three. Actions call `player.back()`, `play()`/`stop()`, `next()`. |
| `QueueTableView.swift` (new, macOS) | `NSScrollView` + single-column view-based `NSTableView` (`headerView = nil`, `style = .plain`, `selectionHighlightStyle = .none`, uniform column autoresizing, zero `intercellSpacing`), data source over `[QueuedTrack]`, fixed `rowHeight` from `QueuedTrackCellView.rowHeight`. `func setQueuedTracks(_:)` reloads and, when the last id changed, scrolls to the last row; on the first population the view has just been added and has no frame yet, so call `window?.layoutIfNeeded()` before `scrollRowToVisible`. Fed by the queue panel controller's `observeChanges` block. |
| `LowerLineWidths.swift` (new, platform-neutral, also in `dmusTests`) | `nonisolated enum LowerLineWidths { static func split(available:albumIdeal:artistIdeal:) -> (album: CGFloat, artist: CGFloat) }` porting `SharedWidthLayout.widths(for:)` from `QueuedTrackRow.swift` (leading cap 60% rounded down, album keeps up to the remainder when the artist fits, 8pt trailing padding on the album). Own file so it stays platform-neutral and has two consumers (cell view and tests). |
| `LowerLineWidthsTests.swift` (new, `dmusTests`) | Requirements cases: both fit (each takes its ideal), both long (60/40), long album with short artist (album takes the remainder), short album with long artist (artist takes the remainder). |
| `QueuedTrackCellView.swift` (new, macOS) | `NSTableCellView` subclass (flipped) with three label `NSTextField`s: track name (single line, tail truncation), album and artist (`.secondaryLabelColor`, `preferredFont(forTextStyle: .subheadline)`, artist right-aligned, both truncating), 8pt horizontal padding. Overrides `layout()` to place the lower line using `LowerLineWidths.split`, measuring ideal widths with `cell.cellSize` because a truncating label's `intrinsicContentSize` reports the width it was last given rather than the width its text wants (the first build elided "Away From The Sun" in an empty row). `static let rowHeight` computed from font metrics (body line height + subheadline line height + 2pt spacing + 4pt padding top and bottom, 40pt in practice, matching the SwiftUI row pitch), since a manually laid-out cell has no fitting size. |
| `QueuePanel.swift`, `PlayerPanel.swift`, `QueuedTrackRow.swift` | Wrap in `#if os(iOS)` in step 5; remove `.dropDestination(for: FolderChild.self)` from `QueuePanel` (drop is a macOS-only requirement and this was the only `Transferable` user); `SharedWidthLayout` stays as the iOS implementation. |

### Settings (`dmus/settings/`)

| File | Change |
|---|---|
| `SettingsWindowController.swift` (new, macOS) | `NSWindow(styleMask: [.titled, .closable])`, title "Dmus Settings", content width 600, `isRestorable = false`, `isReleasedWhenClosed = false`. Content: a horizontal `NSStackView` (first-baseline aligned) of the label "Music Files:", a `ReadOnlyTextField` and a push `NSButton("Choose…")` inside a plain container with 16pt edge insets and a 600pt width constraint; a one-row `NSGridView` would add nothing over the stack. The window takes `contentView.fittingSize` (54pt tall, one point more than the SwiftUI form) and is centered once in `init`. `observeChanges` on `store.musicRootDirectory` calls `pathField.setText`. `chooseMusicRootDirectory` moves over verbatim from `SettingsView.swift` (`NSOpenPanel`, directories only, `directoryURL`, `allowedContentTypes = [.mp3, .mpeg4Audio]`, `runModal`). The AX tree is flat: `static text 2` is the path, `button "Choose…"` the button, no `group 1`. |
| `ReadOnlyTextField.swift` | Replace the `NSViewRepresentable` with a plain `NSTextField` subclass `ReadOnlyTextField` keeping the existing setup (`isEditable = false`, `isSelectable = true`, `isBezeled = true`, `.byTruncatingMiddle`, low horizontal compression resistance and hugging, `clipsToBounds = true`), `override var canBecomeKeyView: Bool { false }` with its existing comment, and `func setText(_:)` that keeps the `abortEditing()` guard from `updateNSView`. |
| `SettingsView.swift` | Delete in step 6. |

### Project, docs, tooling

| File | Change |
|---|---|
| `dmus.xcodeproj/project.pbxproj` | Membership exceptions: add `Observing.swift`, `files/FolderChild+Pasteboard.swift`, `queue/LowerLineWidths.swift` and the three new test files to the `dmusTests` exception set; add the three test files to the `dmus` target's exclusion set. Xcode rewrites shared schemes when it reloads an externally edited pbxproj, so edit the pbxproj first and `git diff xcshareddata/xcschemes` afterwards. |
| `docs/requirements.md` | Line 30: replace "Dmus shall use Swift language and the SwiftUI framework." with: Dmus shall use the Swift language; on macOS, the UI shall use AppKit with all windows, views and menus created programmatically, without nibs or storyboards; on iOS, the UI shall use SwiftUI. Add a "Standard menus" subsection under Menus listing the App, File, Edit and Window menus and their items. |
| `.claude/skills/launch-mac-app/SKILL.md` | First-launch window size is now reset by deleting the `NSWindow Frame main` key from `~/Library/Containers/cc.donm.dmus/Data/Library/Preferences/cc.donm.dmus.plist`; `-ApplePersistenceIgnoreState YES` stays harmless. The bare-binary launch still orders the window on screen without activating the app, same as today. |
| Memory files (after implementation) | Update `driving-mac-app-ui-with-system-events` and `testing-macos-window-size`: System Events `click button` now fires real `NSButton`s with AX titles, Settings controls are no longer nested in `group 1`, frame persistence is the autosave key. |

## Steps

1. **Requirements first.** Edit `docs/requirements.md` as above.
2. **AppKit shell with hosted SwiftUI.** Add `DmusAppDelegate`, `MainMenu`,
   `MainWindowController`, `SettingsWindowController` (temporarily hosting
   `SettingsView` in an `NSHostingView`) and `MainViewController` whose
   `loadView` temporarily creates a 900×600
   `NSHostingView(rootView: MainView().environment(store).environment(player))`.
   Make `dmusApp.swift` iOS-only. Delete `Scene+ContentArea.swift`. Verify:
   window at 900×600 content size, minimum 640×480, title "Dmus", no tab items
   in the Window menu, closing the window quits, "Settings…" opens "Dmus
   Settings", no secure-restorable-state warning in the log, iOS build
   unchanged.
3. **Building blocks.** `Observing.swift` + tests, `PanelView`,
   `EmptyStateView`. Build one `#Preview` with `import DeveloperToolsSupport`
   to confirm the macro resolves before writing the rest. Add membership
   exceptions. `make check`.
4. **Files panel.** `FilesTreeNode`, `FolderChild+Pasteboard` + tests,
   `FilesTreeView`, `FilesPanelViewController`. `MainViewController` becomes
   the real stack view with the files controller on the left and, for now, a
   hosted SwiftUI `QueuePanel` on the right. Wrap `MainView.swift`,
   `FilesPanel.swift` and `FindButton.swift` in `#if os(iOS)`; delete
   `FilesTree.swift`. Verify tree contents in both modes, disclosure
   triangles, expand/collapse, drag onto the hosted queue.
5. **Queue panel.** `LowerLineWidths` + tests, `QueuedTrackCellView`,
   `QueueTableView`, `PlayerPanelView`, `QueuePanelViewController` with
   `DropTargetView`. Wire into `MainViewController`; remove the hosted
   `QueuePanel`. Wrap `QueuePanel.swift`, `PlayerPanel.swift`,
   `QueuedTrackRow.swift` and `Panel.swift` in `#if os(iOS)` and remove
   `.dropDestination`;
   delete `FolderChild+Transferable.swift`. Verify drag and drop of a track
   and of a folder (preorder), clear button, play/stop/back/next with short
   clips, scroll-to-end, row elision at 640 width, scroll position kept when
   adding.
6. **Settings.** Replace the hosted `SettingsView` with the programmatic grid
   and `ReadOnlyTextField` subclass; delete `SettingsView.swift`. Verify the
   path shows, Tab skips the field, click-select and ⌘C work, Choose… opens
   the panel at the current path with non-music files dimmed, choosing a
   folder reloads the library.
7. **Finish.** Confirm no file compiled for macOS imports SwiftUI
   (`grep -rl "import SwiftUI" dmus` must list only files whose first code
   line is `#if os(iOS)`); confirm no `NSHostingView` remains. Update the
   skill doc and memories. `make check`. Compare before/after screenshots of
   both modes for title-bar material and font parity. Done 2026-11-04: the
   only visible difference left is that the SwiftUI files list drew an
   inset separator under each row and the outline view does not; the
   requirements do not ask for separators.

## Verification

- `make check` after every step (runs `dmusTests`, `ModelTests`,
  `WrappersTests` on macOS and the iOS simulator).
- `.claude/skills/launch-mac-app/scripts/launch-mac-app.sh --build --screenshot …`
  and `--demo --screenshot …` after steps 2, 4, 5, 6, 7; inspect the PNGs and
  the stderr log the script prints.
- Window size: delete the `NSWindow Frame main` key with `defaults delete` on
  the container domain path (`~/Library/Containers/cc.donm.dmus/Data/Library/Preferences/cc.donm.dmus`,
  no `.plist`) and read it back the same way; `plutil -p` on the file lags
  cfprefsd and shows stale contents. Launch, read the window bounds with the skill's `window-id` tool (frame
  height minus the 28pt title bar must be 600); resize with a CGEvent edge
  drag toward 640×480 and confirm it clamps; quit and relaunch to confirm the
  size persists.
- Drag and drop: activate the launched pid first (per the drag-and-drop
  memory), CGEvent drag from a tree row to the queue panel; confirm rows
  appear and the table scrolls to the end; drag a folder and confirm preorder.
- Playback: point Settings at a folder of 5s `say`-generated clips, click
  play/stop/back/next via System Events, watch the queue shrink as tracks end.
- Settings: open via `menu item "Settings…"`, confirm AX exposes the field as
  static text and the button as "Choose…", drive `NSOpenPanel` with ⌘⇧G.
- Sandbox: `codesign -d --entitlements :- Dmus.app | plutil -p -` on the plain
  build still shows only the four sandbox keys plus `get-task-allow`.
- iOS: `make check` builds and tests the simulator; launch once in the
  simulator to confirm the SwiftUI UI is untouched.
