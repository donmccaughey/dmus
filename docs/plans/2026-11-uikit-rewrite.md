# Move the iOS app from SwiftUI to programmatic UIKit

## Context

Dmus is a single multiplatform Xcode target (`dmus`, product `Dmus.app`) that
builds for macOS and iOS from one source folder, splitting platform code with
whole-file `#if os(...)`. The macOS UI was rewritten in programmatic AppKit in
November 2026 (`docs/plans/completed/2026-11-appkit-rewrite.md`). The iOS UI
is still SwiftUI: nine whole-file `#if os(iOS)` files, about 470 lines, 40% of
which are previews. It is to be rewritten with UIKit classes created in code:
no nibs, no storyboards, and no `UIHostingController` or `import SwiftUI` in
the finished build (after this, nothing in `dmus/` imports SwiftUI). The model
layer (`MusicLibraryStore`; `Player`, `Queue`, `MusicLibrary` in `dmusBase`)
is reused unchanged, as are the platform-neutral helpers the AppKit rewrite
left behind: `observeChanges` in `dmus/Observing.swift` and `LowerLineWidths`
in `dmus/queue/LowerLineWidths.swift`.

The iOS UI is: a main view of two equal panels, stacked in portrait and side
by side in landscape (chosen by aspect ratio, width > height); a files panel
that is a navigation stack of plain folder tables with add/open row buttons; a
queue panel with player controls and a queue table that scrolls to the end on
add. There is no settings UI, no drag and drop, and the Find buttons have no
action on either platform. Everything SwiftUI did implicitly (scene and window
creation, observation-driven redraws, navigation bar appearance, safe areas,
Dynamic Type) becomes explicit code.

## Decisions

- **Incremental, always launchable.** Step 3 installs the UIKit app shell
  (app delegate, scene delegate, window, `MainViewController`) and temporarily
  hosts the SwiftUI `MainView` in a `UIHostingController`. Later steps replace
  one panel at a time and delete the SwiftUI files they replace in the same
  step (every SwiftUI file is already iOS-only, so nothing needs `#if`
  wrapping). Each step builds for both platforms, passes `make check`, and is
  verified in the simulator with the new `launch-ios-app` skill.
- **Same type names as AppKit, suffixed file names.** The UIKit classes take
  the AppKit names (`MainViewController`, `PanelView`, `EmptyStateView`,
  `FilesPanelViewController`, `QueuePanelViewController`, `PlayerPanelView`,
  `QueueTableView`, `QueuedTrackCellView`, `DmusAppDelegate`); the two
  implementations never compile together because both files are whole-file
  `#if os(...)`. Where a type has a twin, the files are `Name-macOS.swift` and
  `Name-iOS.swift` (a hyphen, matching `dmus-iOS.entitlements`; `Name+iOS`
  would read as an extension file). Types that exist on one platform only keep
  plain file names (`MainMenu.swift`, `FilesTreeView.swift`,
  `DmusSceneDelegate.swift`, `FolderTableViewController.swift` …). The
  renames are a `git mv` with no pbxproj change: the synchronized group picks
  them up and none of the renamed files is in an exception set. Interim UIKit
  names must not collide with the SwiftUI structs still present mid-migration
  (`MainView`, `Panel`, `FilesPanel`, `FilesTableStack`, `FolderTable`,
  `FolderRow`, `TrackRow`, `FindButton`, `QueuePanel`, `PlayerPanel`,
  `QueuedTrackRow`); the new iOS-only names (`DmusSceneDelegate`,
  `HairlineView`, `PanelArrangement`, `FilesTableStackController`,
  `FolderTableViewController`, `FolderChildCell`) all clear that.
- **Scenes, configured in code.** The build already generates a scene
  manifest with `UIApplicationSupportsMultipleScenes = true` and an empty
  `UISceneConfigurations` dict (checked in the built `Info.plist`). With an
  empty list UIKit asks the app delegate, so
  `application(_:configurationForConnecting:options:)` returns a
  `UISceneConfiguration(name: nil, sessionRole:)` with `delegateClass =
  DmusSceneDelegate.self` (the header says a nil-named configuration has a
  nil delegate class, so it must be set). No plist or pbxproj edits, and
  multiple iPad scenes keep working as under SwiftUI: the app delegate owns
  the one `store` and `player`, and every scene's window shares them. Unlike
  AppKit, the `main()` UIKit synthesizes for a `@main` `UIApplicationDelegate`
  class passes the class name to `UIApplicationMain`, which instantiates it,
  so no custom `main()` is needed. UIKit creates the scene delegate with
  `init()`, so it reaches the store and player through
  `UIApplication.shared.delegate`.
- **Observation bridge** is the existing `observeChanges`; iOS 18 UIKit has
  no automatic observation tracking (that arrives with iOS 26). `UIView` is an
  `NSObject`, so the same `observe(...)` shadowing that forced the name on
  macOS applies. Blocks capture `self` weakly and never read
  `player.timeIndex`.
- **Arrangement rule** stays aspect-ratio based (`width > height` →
  side by side, so a square is stacked), as `MainView`'s `GeometryReader`
  did, which also covers iPad Split View, Slide Over and Stage Manager. It is
  extracted to a platform-neutral, unit-tested `PanelArrangement` enum and
  evaluated in `viewWillLayoutSubviews` from `view.bounds`.
- **Safe areas: full-bleed stack, safe-area-aware children.** The panel
  stack is pinned to the root view's edges. SwiftUI's `.background(style)`
  ignores safe-area edges by default and `List` scrolls under them, so the
  SwiftUI build drew title-bar and navigation-bar backgrounds to the screen
  edge with text inside the safe area; the UIKit build does the same by
  pinning `PanelView`'s label and accessory to the title bar's own
  `safeAreaLayoutGuide` and letting `UINavigationController`, `UITableView`
  and `UIContentUnavailableView` handle their own insets. To keep the two
  usable halves equal as SwiftUI did (it split the safe area, not the
  screen), the equal-size constraint carries a constant of
  `safeAreaInsets.top - bottom` (stacked) or `left - right` (side by side),
  refreshed in `viewWillLayoutSubviews`. Without it the files panel would be
  about 12pt shorter in usable terms on an iPhone 16e.
- **Equal halves** use `distribution = .fill` with an explicit equal-width or
  equal-height constraint between the two panel views, swapped with the axis,
  because `.fillEqually` would also equalize the hairline separator (the
  pitfall the AppKit plan hit). Hairlines are a small `HairlineView` with an
  intrinsic thickness of `1 / displayScale` points and required hugging on
  the thin axis, as SwiftUI's `Divider` draws.
- **System components over hand-built ones.** `EmptyStateView` subclasses
  `UIContentUnavailableView` (iOS 17+), the UIKit face of the same design as
  SwiftUI's `ContentUnavailableView`, so the empty states keep the system
  metrics with no measuring step (the AppKit version had to be measured).
  Folder rows use `defaultContentConfiguration()`. Buttons are
  `UIButton(configuration:)`: `.bordered()` for Find, Clear and the player
  controls, `.plain()` for row buttons; they scale with Dynamic Type and dim
  when disabled on their own.
- **Queue rows have a fixed height**, as on macOS, computed from the body and
  subheadline `lineHeight` plus the 2pt line spacing and 4pt padding,
  recomputed on content-size-category changes. Fixed heights make
  `scrollToRow(at:at: .bottom)` exact; self-sizing with estimated heights
  is the classic cause of "scrolled almost to the end". The cell lays its
  three labels out in `layoutSubviews` with `LowerLineWidths.split`;
  `UILabel.intrinsicContentSize.width` is the text's natural width even when
  truncating, so no `cellSize` workaround is needed.
- **Row buttons.** UIKit has no equivalent of the SwiftUI pitfall where a
  `Button` inside a `NavigationLink` label never fires: a `UIButton` in a
  cell's `accessoryView` takes the touch before row selection. Folder rows
  push on row tap and on the chevron button; track rows are not selectable.
  A cell sizes its `accessoryView` from the view's frame, never from
  constraints, so the accessory stack's frame is set from its fitting size.
- **Previews.** `#Preview` is kept for UIKit views and controllers with the
  macOS sample data. The `UIView`/`UIViewController` overloads live in UIKit's
  Swift overlay; files still `import DeveloperToolsSupport` for the `traits:`
  (`.portrait`, `.landscapeLeft`) and registry types, never SwiftUI. Step 4
  builds one first to confirm the macro resolves.
- **Dynamic Type and appearance.** Semantic `UIColor`s give dark mode for
  free. Every `UILabel` sets `preferredFont(forTextStyle:)` and
  `adjustsFontForContentSizeCategory = true`; manual-layout code registers
  for `UITraitPreferredContentSizeCategory` (the hairline for
  `UITraitDisplayScale`) with `registerForTraitChanges`.
- **Verification runtime.** Xcode 26 builds against the iOS 26 SDK, and on an
  iOS 26 simulator both the old and new UI take the new system design, so
  parity is checked on the iOS 18.4 iPhone 16e that `make check` already
  uses. Baseline screenshots of the SwiftUI app are captured in step 1
  before anything changes.
- **Testable logic** is extracted to platform-neutral files and tested in
  `dmusTests` (membership exceptions in `project.pbxproj`; edit the pbxproj
  first and `git diff xcshareddata/xcschemes` after, since Xcode rewrites
  schemes on reload). `PanelArrangement` is the only rule worth a seam; the
  "did not load" description choice and the "last id changed" scroll trigger
  are two-liners.
- **Out of scope.** No iOS settings UI or file import (there is still no way
  to put music on an iOS device; `docs/drafts/file-sync.md` is not consulted).
  Find buttons stay action-less. `UIBackgroundModes` audio is not added.

## Files

### Renames (`git mv`, step 2)

| From | To |
|---|---|
| `dmus/DmusAppDelegate.swift` | `dmus/DmusAppDelegate-macOS.swift` |
| `dmus/MainViewController.swift` | `dmus/MainViewController-macOS.swift` |
| `dmus/PanelView.swift` | `dmus/PanelView-macOS.swift` |
| `dmus/EmptyStateView.swift` | `dmus/EmptyStateView-macOS.swift` |
| `dmus/files/FilesPanelViewController.swift` | `dmus/files/FilesPanelViewController-macOS.swift` |
| `dmus/queue/QueuePanelViewController.swift` | `dmus/queue/QueuePanelViewController-macOS.swift` |
| `dmus/queue/PlayerPanelView.swift` | `dmus/queue/PlayerPanelView-macOS.swift` |
| `dmus/queue/QueueTableView.swift` | `dmus/queue/QueueTableView-macOS.swift` |
| `dmus/queue/QueuedTrackCellView.swift` | `dmus/queue/QueuedTrackCellView-macOS.swift` |

### Shared app infrastructure (`dmus/`)

| File | Change |
|---|---|
| `DmusAppDelegate-iOS.swift` (new, iOS) | `@main final class DmusAppDelegate: UIResponder, UIApplicationDelegate`. `let store = MusicLibraryStore()`, `let player = Player()`, `static var shared: DmusAppDelegate { UIApplication.shared.delegate as! DmusAppDelegate }`. `application(_:didFinishLaunchingWithOptions:)` calls `store.loadInBackground(isDemo: CommandLine.arguments.contains("--demo"))` and returns true. `application(_:configurationForConnecting:options:)` returns `UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)` with `delegateClass = DmusSceneDelegate.self`. No custom `main()`. |
| `DmusSceneDelegate.swift` (new, iOS) | `final class DmusSceneDelegate: UIResponder, UIWindowSceneDelegate { var window: UIWindow? }`. `scene(_:willConnectTo:options:)`: guard `UIWindowScene`, `windowScene.title = "Dmus"` (keeps the `WindowGroup("Dmus")` title in the iPad app switcher), `window = UIWindow(windowScene:)`, `rootViewController = MainViewController(store: DmusAppDelegate.shared.store, player: DmusAppDelegate.shared.player)`, `makeKeyAndVisible()`. |
| `MainViewController-iOS.swift` (new, iOS) | `init(store:player:)`; `required init?(coder:)` unavailable (the same fatalError idiom as the AppKit classes). `loadView` overrides without calling super (so UIKit never looks for a nib) and creates a `UIView` with `backgroundColor = .systemBackground` holding a `UIStackView` (spacing 0, `.fill`) of `filesPanel.view`, a `HairlineView`, `queuePanel.view`, pinned to the view's edges; both panels added with `addChild` + `didMove(toParent:)`. Two constraint sets: side by side (`hairline.axis = .vertical`, `files.widthAnchor == queue.widthAnchor + c`) and stacked (`hairline.axis = .horizontal`, `files.heightAnchor == queue.heightAnchor + c`). `viewWillLayoutSubviews`: compute `PanelArrangement(fitting: view.bounds.size)`; when it differs from the current one swap `stack.axis` and the active set; on every pass refresh `c` from `view.safeAreaInsets` (top − bottom stacked, left − right side by side). In step 3 `loadView` instead adds a child `UIHostingController(rootView: MainView().environment(store).environment(player))` filling the view. Previews `#Preview("Portrait", traits: .portrait)` and `#Preview("Landscape", traits: .landscapeLeft)`. |
| `PanelArrangement.swift` (new, platform-neutral, also in `dmusTests`) | `nonisolated enum PanelArrangement: Equatable { case sideBySide, stacked; init(fitting size: CGSize) }` with `width > height ? .sideBySide : .stacked`. Own file so the rule is platform-neutral and has two consumers. |
| `PanelArrangementTests.swift` (new, `dmusTests` only) | Wider than tall → side by side; taller than wide → stacked; square → stacked (strict `>`, the SwiftUI rule). |
| `PanelView-iOS.swift` (new, iOS) | `final class PanelView: UIView`: a vertical `UIStackView` (`.fill`) of `titleBar`, `HairlineView`, `contentContainer` filling the view. Title bar: `backgroundColor = .secondarySystemBackground` (the requirements call for it, and it must stay solid because the folder table's navigation bar uses the same colour); a `UILabel` with `preferredFont(forTextStyle: .headline)`, `adjustsFontForContentSizeCategory`, centred, constrained to `titleBar.safeAreaLayoutGuide` (centerX, top +16, bottom −16); optional accessory at `safeAreaLayoutGuide.trailingAnchor − 8`, centred on the label. `init(title:accessory:)`; `func setContent(_ view: UIView)` (no-op when unchanged, otherwise replace via `addFillingSubview`); `var showsTitle: Bool` sets `isHidden` on the title bar and hairline (hidden arranged subviews leave the layout). |
| `UIView+FillingSubview.swift` (new, iOS) | `extension UIView { func addFillingSubview(_ view: UIView) }`, the twin of `NSView+FillingSubview.swift`. |
| `HairlineView.swift` (new, iOS) | `UIView` with `backgroundColor = .separator`, `var axis: NSLayoutConstraint.Axis` (`.horizontal` line: intrinsic height `1 / traitCollection.displayScale`, width `noIntrinsicMetric`; `.vertical` the reverse); `invalidateIntrinsicContentSize()` on axis change and on `UITraitDisplayScale` changes; required hugging and compression resistance on the thin axis so `.fill` stacks never stretch it. Used by `MainViewController`, `PanelView`, `QueuePanelViewController`. |
| `EmptyStateView-iOS.swift` (new, iOS) | `final class EmptyStateView: UIContentUnavailableView`. `init(title:systemImage:description:)` builds `UIContentUnavailableConfiguration.empty()` with `image = UIImage(systemName:)`, `text`, `secondaryText`, and calls `super.init(configuration:)`; `var descriptionText: String` reads and writes `configuration.secondaryText` (the Swift import is a value type: copy, mutate, assign back). Same API as the macOS class. |
| `Observing.swift` | Widen the comment from "AppKit before macOS 26" to AppKit before macOS 26 and UIKit before iOS 26 (step 7). |
| `dmusApp.swift` | Delete in step 3. |
| `MainView.swift` | Delete in step 5 (hosted through step 4). |
| `Panel.swift` | Delete in step 6 (the hosted `QueuePanel` still uses it in step 5). |

### Files panel (`dmus/files/`)

| File | Change |
|---|---|
| `FilesPanelViewController-iOS.swift` (new, iOS) | `loadView`: `view = PanelView(title: "Files", accessory: findButton)`; `findButton = UIButton(configuration: .bordered())` titled "Find", `isEnabled = false` always (the requirements say the panel copy is a disabled placeholder). Holds an `EmptyStateView("No music", "folder", "")` and a child `FilesTableStackController` added with `addChild`/`didMove` in `loadView`. `viewDidLoad` starts one `observeChanges` block reading `store.library` and `store.loadDidFail`: when empty, set `descriptionText` ("The music library did not load." / "The music library is empty."), `panelView.showsTitle = true`, `setContent(emptyStateView)`; otherwise `showsTitle = false`, `filesTableStack.setRootFolder(library.rootFolder)`, `setContent(filesTableStack.view)`. The block also re-runs when `loadErrors` changes and must not reset the stack then (hence the equality guard below). Previews "Empty" and "Loaded" as on macOS (`store.apply(LoadResult(...))`). |
| `FilesTableStackController.swift` (new, iOS) | `final class FilesTableStackController: UINavigationController`. `init(player:)` calls `super.init(nibName: nil, bundle: nil)`; configures `navigationBar.standardAppearance` and `scrollEdgeAppearance` from one `UINavigationBarAppearance` with `configureWithOpaqueBackground()` and `backgroundColor = .secondarySystemBackground` (the compact variants fall back to these), so the bar is opaque at every scroll position as the requirements demand. `private(set) var rootFolder: Folder?`; `func setRootFolder(_:)` returns when equal (`Folder` is `Hashable`, so the user's navigation position survives a reload of the same library), else `setViewControllers([FolderTableViewController(folder:player:)], animated: false)`. |
| `FolderTableViewController.swift` (new, iOS) | `final class FolderTableViewController: UITableViewController` created with `style: .plain`. `init(folder:player:)`; `navigationItem.title = folder.name`, `largeTitleDisplayMode = .never`, `rightBarButtonItem = UIBarButtonItem(customView: findButton)` where `findButton` is a bordered "Find" `UIButton`, enabled, no action (like the SwiftUI one). Registers `FolderChildCell`; `tableFooterView = UIView()` if the baseline shows no separators below the last row. Data source over `folder.children`: `cellForRowAt` calls `cell.show(child, onAdd: { player.queue.add(child) }, onOpen: { push(folder) })`. `willSelectRowAt` returns nil for track rows; `didSelectRowAt` pushes `FolderTableViewController(folder:player:)` for folder rows (`clearsSelectionOnViewWillAppear` deselects on return). |
| `FolderChildCell.swift` (new, iOS) | `final class FolderChildCell: UITableViewCell`, `static let reuseIdentifier`. `show(_:onAdd:onOpen:)`: `var content = defaultContentConfiguration(); content.text = child.name; contentConfiguration = content`; `accessoryView` is a horizontal `UIStackView` of two `UIButton(configuration: .plain())`: add (`plus.square` for folders, `plus.circle` for tracks, `accessibilityLabel` "Add") and open (`chevron.right`, `tintColor = .tertiaryLabel`, `accessibilityLabel` "Open", hidden for tracks). After configuring, `accessory.frame.size = accessory.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)`; the content configuration then lays out in the remaining width and truncates before the accessory. `selectionStyle = .default` for folders, `.none` for tracks. Actions are `UIAction`s replaced on each `show`, so a reused cell never fires a previous row's closure. |
| `FilesPanel.swift`, `FilesTableStack.swift`, `FindButton.swift` | Delete in step 5. |

### Queue panel (`dmus/queue/`)

| File | Change |
|---|---|
| `QueuePanelViewController-iOS.swift` (new, iOS) | `loadView`: `view = PanelView(title: "Queue", accessory: clearButton)`; `clearButton = UIButton(configuration: .bordered(), primaryAction: UIAction { player.clear() })` titled "Clear". Content is `EmptyStateView("No tracks", "list.bullet", "The queue is empty.")` or a lazily built `queueView`: a vertical `.fill` `UIStackView` of `PlayerPanelView`, `HairlineView`, `QueueTableView` (table `defaultLow` vertical hugging, player panel required). One `observeChanges` block reads `player.queue.queuedTracks`, sets `clearButton.isEnabled`, swaps the content (no-op when unchanged, so scroll position survives adds) and then calls `queueTableView.setQueuedTracks(_:)`; one block keeps the swap ahead of the first scroll-to-end, as on macOS. Previews "Empty" and "Filled" with the macOS sample data. |
| `PlayerPanelView-iOS.swift` (new, iOS) | `final class PlayerPanelView: UIView`. Horizontal `UIStackView` (centred, spacing 8, SwiftUI's default `HStack` spacing) of three `UIButton(configuration: .bordered())` image-only buttons (`backward.fill`, `play.fill`/`stop.fill`, `forward.fill`); width constraints `buttonWidth` / `buttonWidth * 1.2` / `buttonWidth` on the whole button so the 20% ratio is exact, `buttonWidth` measured from the SwiftUI baseline (SwiftUI used a 44pt label frame plus the bordered insets); 16pt padding all round via `directionalLayoutMargins`; required vertical hugging so the stack gives it its fitting height. `accessibilityLabel`s "Back", "Play"/"Stop", "Next". Actions are `UIAction`s calling `player.back()`, `play()`/`stop()`, `next()`. `observeChanges` reads `player.isPlaying` and `player.queue.isEmpty`: sets `isEnabled` on all three and swaps the middle image and label by reassigning `configuration`. Previews "Empty" and "Queued". |
| `QueueTableView-iOS.swift` (new, iOS) | `final class QueueTableView: UIView` wrapping a `UITableView(frame: .zero, style: .plain)` filling it: `allowsSelection = false`, `rowHeight = QueuedTrackCellView.rowHeight(for: traitCollection)`, registers `QueuedTrackCellView`, a data source object over `[QueuedTrack]`, `tableFooterView = UIView()` if needed for parity. Plain tables inset separators to the cell layout margin by default, which matches the SwiftUI plain list. `registerForTraitChanges([UITraitPreferredContentSizeCategory.self])` recomputes `rowHeight` and reloads. `func setQueuedTracks(_:)`: store, `reloadData()`, and when the last `id` changed scroll to the end: `window?.layoutIfNeeded()` first (the first tracks arrive in the turn that puts the view on screen, before it has a frame), then `scrollToRow(at: last, at: .bottom, animated: false)`. |
| `QueuedTrackCellView-iOS.swift` (new, iOS) | `final class QueuedTrackCellView: UITableViewCell`, `static let reuseIdentifier`, `init(style:reuseIdentifier:)`. Three `UILabel`s in `contentView`: track (body, `.label`), album and artist (`preferredFont(forTextStyle: .subheadline)`, `.secondaryLabel`, artist `textAlignment = .right`), all one line, `.byTruncatingTail`, `adjustsFontForContentSizeCategory`. `show(_ track:)` sets the text and `setNeedsLayout()`. `layoutSubviews()` places the track label across `contentView.layoutMarginsGuide` (the margin matches the separator inset and the SwiftUI row's leading padding), then the lower line via `LowerLineWidths.split(available:albumIdeal: albumLabel.intrinsicContentSize.width + albumTrailingPadding, artistIdeal: artistLabel.intrinsicContentSize.width)`. `static func rowHeight(for traitCollection:)` = 4 + body `lineHeight` + 2 + subheadline `lineHeight` + 4, rounded up, fonts from `preferredFont(forTextStyle:compatibleWith:)`; the padding is adjusted to the baseline screenshot's row pitch. |
| `LowerLineWidths.swift` | Replace the comment that points at `SharedWidthLayout` in `QueuedTrackRow.swift` (deleted in step 6) with a self-contained description of the rule. |
| `QueuePanel.swift`, `PlayerPanel.swift`, `QueuedTrackRow.swift` | Delete in step 6. |

### Project, docs, tooling

| File | Change |
|---|---|
| `dmus.xcodeproj/project.pbxproj` | Membership exceptions (step 4): add `PanelArrangement.swift` and `PanelArrangementTests.swift` to the `dmusTests` exception set; add `PanelArrangementTests.swift` to the `dmus` target's exclusion set. Nothing else changes: the renamed files are in neither set and the Info.plist keys stay. |
| `docs/requirements.md` | Line 38: replace "On iOS, dmus shall use the SwiftUI framework for its user interface." with two sentences mirroring the macOS ones: On iOS, dmus shall use the UIKit framework for its user interface, rather than SwiftUI. On iOS, dmus shall create all scenes, windows, views and view controllers programmatically and shall not use nibs or storyboards. Line 534 is a truncated sentence ("dmus shall push .") and is completed while there: push a new folder table backed by that folder onto the files table stack. |
| `docs/plans/2026-11-uikit-rewrite.md` | This plan; moved to `docs/plans/completed/` in step 7, as the AppKit plan was. |
| `.claude/skills/launch-ios-app/SKILL.md` and `scripts/launch-ios-app.sh` (new) | Modelled on `launch-mac-app`. `launch-ios-app.sh [--demo] [--build] [--screenshot PATH] [--landscape] [--udid UDID] [--keep] [--wait SECONDS]`. Default device: the iOS 18.4 iPhone 16e (the `make check` device) resolved by name and runtime from `xcrun simctl list -j devices available` to a UDID (an `id=` destination avoids the ambiguous `name=`); boots it with `simctl bootstatus -b` and opens Simulator.app if needed. `--build` runs `xcodebuild -project dmus.xcodeproj -scheme dmus -destination "platform=iOS Simulator,id=$udid" -quiet build`; the app is found via `-showBuildSettings` (`BUILT_PRODUCTS_DIR`, `FULL_PRODUCT_NAME`: product is `Dmus.app`, capital D). Then `simctl terminate` (ignoring failure, so each run starts with an empty queue), `simctl install`, `simctl launch --stderr=<log> $udid cc.donm.dmus [--demo]` (prints the pid). `--landscape` activates Simulator.app and sends ⌘← through System Events, the only rotation path (the user has granted Accessibility), then re-queries the window. Waits, then `xcrun simctl io $udid screenshot PATH` (needs no window permission; pixels are 3x on the 16e). `simctl terminate` unless `--keep`. SKILL.md records the pitfalls from the `testing-ios-app-in-simulator` memory (raise the device window before a System Events `click at`; window names carry the OS version; scroll with a CGEvent drag, not the scroll wheel; point mapping), the expected contents of each mode ("3 Doors Down" first in demo), and that the stderr log is where Auto Layout conflicts appear. |
| `.claude/skills/investigate-issue/SKILL.md` | Replace its inline iPhone 15 simulator recipe with a call to the new script. |
| Memory files (after implementation) | Update `testing-ios-app-in-simulator`: the NavigationLink pitfall is gone, buttons are real `UIButton`s with accessibility labels, launch via the skill, `simctl io screenshot`. Add notes for UIKit lessons that surface (accessory frame sizing, fixed row height for exact scroll-to-end, safe-area constant). Update `MEMORY.md`. |

## Steps

1. **Requirements, skill, baselines.** Edit `docs/requirements.md` as
   above. Write the `launch-ios-app` skill and prove it on the current
   SwiftUI build on the iOS 18.4 iPhone 16e: normal mode (empty library) and
   `--demo`, portrait and landscape, plus demo with a folder added to the
   queue (tap "+" via System Events) and a pushed folder table. Keep the
   PNGs in the scratchpad as the baselines every later step is compared
   against. `make check`.
2. **Renames.** `git mv` the nine macOS twins to `-macOS` names. Build both
   platforms; `make check`; `launch-mac-app --build --demo --screenshot` to
   confirm the AppKit build is untouched.
3. **UIKit shell with hosted SwiftUI.** Add `DmusAppDelegate-iOS.swift`,
   `DmusSceneDelegate.swift`, and `MainViewController-iOS.swift` whose
   `loadView` temporarily hosts `MainView` in a child `UIHostingController`
   (this file alone imports SwiftUI for now). Delete `dmusApp.swift`.
   Verify: app launches in both modes, UI unchanged against the baselines,
   rotation still switches the arrangement, "Dmus" shows in the iPad app
   switcher, no warnings in the launch log, macOS build untouched.
4. **Building blocks.** `PanelArrangement` + tests (pbxproj exceptions),
   `UIView+FillingSubview`, `HairlineView`, `PanelView`, `EmptyStateView`.
   Build the first UIKit `#Preview` (`import UIKit` plus
   `import DeveloperToolsSupport`) to confirm the macro resolves before
   writing the rest. `make check`.
5. **Files panel.** `FolderChildCell`, `FolderTableViewController`,
   `FilesTableStackController`, `FilesPanelViewController`.
   `MainViewController` becomes the real stack of the files controller and,
   for now, a child `UIHostingController(rootView:
   QueuePanel().environment(player))` on the other side. Delete
   `MainView.swift`, `FilesPanel.swift`, `FilesTableStack.swift`,
   `FindButton.swift`. Verify in both modes and both orientations: empty
   state with the title and disabled "Find"; loaded state hides the panel
   title and shows the opaque bar with "Files" and the active-looking
   "Find"; bar stays opaque when scrolled; row tap and chevron push, back
   pops; "[+]" on a folder adds its tracks in preorder to the hosted queue;
   "(+)" adds one track; an empty folder shows an empty table; in landscape
   text stays out of the notch while the bar background reaches the edge;
   dark mode via `simctl ui $udid appearance dark`. Compare with the
   baselines. Measure the player button width from the baseline for step 6:
   on the iOS 18.4 iPhone 16e the SwiftUI back and next buttons are 68pt
   wide, play is 76⅔pt (the 20% applies to the 44pt label, not the whole
   button), all are 29⅓pt high with 8pt between them, and the player panel
   is 62⅓pt from hairline to hairline. (Measure across the middle of a
   button; its rounded corners make it look narrower near the top.)
6. **Queue panel.** `QueuedTrackCellView`, `QueueTableView`,
   `PlayerPanelView`, `QueuePanelViewController`; wire into
   `MainViewController` and remove the hosting and the last
   `import SwiftUI`. Delete `QueuePanel.swift`, `PlayerPanel.swift`,
   `QueuedTrackRow.swift`, `Panel.swift`; fix the `LowerLineWidths.swift`
   comment. Verify: empty state and disabled "Clear"; add a folder and the
   table scrolls to the end; the long-named demo entries elide and split
   60/40 at the 16e portrait width; the four requirement cases for the lower
   line (both fit, both long, long album, long artist); "Clear";
   play/stop/back/next against the bundled demo clip (every demo track plays
   `demo-track.mp3`; watch the queue shrink as tracks end); scroll position
   kept when adding; Dynamic Type at an accessibility size
   (`simctl spawn $udid defaults write -g UIPreferredContentSizeCategoryName
   UICTContentSizeCategoryAccessibilityXXXL`, relaunch, then reset)
   re-measures rows; dark mode; both arrangements.
7. **Finish.** `grep -rl "import SwiftUI" dmus` and
   `grep -r UIHostingController dmus` must print nothing. Update the
   `Observing.swift` comment, the skill docs, the investigate-issue recipe
   and the memories. `make check`. Compare final screenshots with the step 1
   baselines in both modes, both orientations, light and dark; the system
   components should leave only differences SwiftUI itself introduced, and
   any accepted ones are recorded here as the AppKit plan did. Run once on
   the iOS 18.4 iPad Pro 11-inch simulator (`--udid`), including a Split
   View width where the window is taller than wide, and open a second window
   from the app switcher to confirm both scenes share one queue. Move the
   plan to `docs/plans/completed/`.

## Differences from the SwiftUI build

Observed on the iOS 18.4 iPhone 16e in steps 4 to 6, for step 7 to accept or
adjust:

- Empty states: `UIContentUnavailableView` centres its icon, title and
  description in the safe area; SwiftUI drew the same block 10pt higher.
- Folder rows are 44⅓pt apart, not 44pt: `UITableView` adds the separator
  to a self-sized row.
- Bordered buttons (Find, Clear) have the same frame and fill but slightly
  different corners and text antialiasing.
- Hairlines run edge to edge; SwiftUI's `Divider` stopped at the safe area,
  which showed in landscape.
- Player panel: a bordered image button is 34⅓pt high in UIKit and 29⅓pt in
  SwiftUI, so the panel is 5pt taller; play is 81⅔pt wide, 20% more than
  the whole 68pt back and next buttons, where SwiftUI's was 76⅔pt.
- The player panel caps Dynamic Type at `accessibilityLarge` so its symbols
  stay inside the fixed-width buttons.
- The queue table scrolls to the end on the first add as well; the SwiftUI
  list only did from the second add on.
- At the largest accessibility sizes the centred "Queue" title runs under
  the "Clear" button. This was not compared with the SwiftUI build.
- iOS 26 only: the folder table's Find button is a bordered pill inside the
  navigation bar's glass capsule; SwiftUI drew one glass capsule. Bordered
  buttons (Find, Clear, the player controls) draw their text and symbols in
  the label colour rather than the tint, which was not compared with the
  SwiftUI build.

## Verification

- `make check` after every step (runs `dmusTests`, including
  `PanelArrangementTests`, plus `ModelTests` and `WrappersTests` on macOS and
  the iPhone 16e simulator).
- `.claude/skills/launch-ios-app/scripts/launch-ios-app.sh --build
  --screenshot …`, `--demo --screenshot …`, each also with `--landscape`,
  after steps 1, 3, 5, 6, 7; view the PNGs with the Read tool and compare
  them against the step 1 baselines by eye.
- Taps: System Events `click at {x, y}` on the raised simulator window per
  the iOS memory (re-query the window position first and map device points
  through the window scale). UIKit buttons fire from real taps, so the add
  buttons, chevron, Find, Clear and the player controls are all exercised
  that way. Scroll the queue with a CGEvent drag.
- Rotation: `--landscape` (⌘←) and back (⌘→); confirm stacked ↔ side by
  side, equal usable halves, and no Auto Layout conflict in the launch
  log.
- Layout debugging: `lldb -p <pid>` on the simulator process (`pgrep -f
  Dmus.app/Dmus`) with
  `expr -l objc -O -- [[[UIApplication sharedApplication] keyWindow] recursiveDescription]`
  dumps every frame, the iOS counterpart of the `_subtreeDescription` trick.
- macOS: unchanged; `launch-mac-app --build --demo --screenshot` after steps
  2 and 7.
