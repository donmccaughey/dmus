# Rewrite MC Mus in Objective-C

## Context

MC Mus is about 4,600 lines of Swift in three places:

- `mcmusBase/`, a local SwiftPM package: `Wrappers` (280 lines),
  `WrappersTestSupport` (230), `Model` (520), and the Swift Testing targets
  `ModelTests` (72 tests, 920 lines) and `WrappersTests` (a placeholder).
- `mcmus/`, one multiplatform app target (macOS AppKit and iOS UIKit, all
  created in code): 40 files, about 2,400 lines, a tenth of them `#Preview`
  blocks, plus `MusicLibraryStoreTests.swift`, which belongs in `mcmusTests/`.
- `mcmusTests/`, a logic-test bundle with no host app (24 tests) that compiles
  five app sources directly through pbxproj membership exceptions.

The whole project is to be rewritten in Objective-C, and `mcmusBase` is to
become a statically linked library: a native static library target in
`mcmus.xcodeproj` rather than a package, since `Package.swift` is itself Swift.
The rewrite is incremental. Every step builds for both platforms, passes
`make check`, and leaves both apps launchable.

Swift gives the current code several things Objective-C has no equivalent for,
and those, not the line-by-line translation, are the real work: value types,
enums with associated values, Observation, structured concurrency, `Codable`,
`throws`, default arguments and overloads, module namespaces, Swift Testing and
`#Preview`. "Rework before translation" below lists each one, where it occurs,
and when it is dealt with.

## Decisions

- **One kind of change per step.** A step changes the shape of an API, or the
  language of an implementation, or the language of its tests, never two of
  them. So the code is first reshaped *in Swift* into something Objective-C
  can express (classes for structs, a protocol for the `FolderChild` enum,
  notifications for Observation), with the existing tests adapted once and
  kept green. Each module is then translated under tests that do not change,
  since Swift tests can exercise Objective-C. Only when a module is stable
  are its tests ported to XCTest. Some of the reshaped Swift is written only
  to be translated a few steps later; that is the price of never changing
  code and its safety net together.
- **Bottom-up, so Swift only ever looks down at Objective-C.** Swift can use
  any Objective-C class; Objective-C cannot see Swift structs, payload enums
  or generics. The order is wrappers, model, fakes, then the app's leaf
  views, its controllers, and the app shell last. The remaining Swift always
  imports finished Objective-C beneath it, and no Objective-C file ever
  imports the generated `MC_Mus-Swift.h`. The app's dependency graph has no
  cycles: the iOS scene delegate reaches the app delegate through
  `MCMusAppDelegate.shared`, and both are named by string, to
  `UIApplicationMain` and in `Info.plist`.
- **The package survives until its sources are all Objective-C.** A SwiftPM
  target cannot mix languages but a package can: a Swift target may depend on
  a C-family target. `Wrappers`, `Model` and `WrappersTestSupport` are
  translated one whole target at a time inside the package, and SwiftPM
  supplies the module maps, so the 40-odd `import Model` / `import Wrappers`
  lines in the remaining Swift keep working untouched. The package then
  becomes Xcode targets in one build-system-only step, while the app is
  still pure Swift. The library's tests are ported after that, file by file,
  in an Xcode test bundle where Swift Testing and XCTest can sit side by
  side; this avoids depending on Objective-C test targets inside SwiftPM.
- **End state of the library.** Two static library targets in
  `mcmus.xcodeproj`, mirroring the package's two products: `mcmusBase`
  (`libmcmusBase.a`, from `mcmusBase/Wrappers/` and `mcmusBase/Model/`) and
  `mcmusBaseTestSupport` (`libmcmusBaseTestSupport.a`, from
  `mcmusBase/WrappersTestSupport/`), plus one logic-test bundle
  `mcmusBaseTests` (from `mcmusBase/ModelTests/` and
  `mcmusBase/WrappersTests/`). Each folder is a file-system-synchronized group
  owned by one target, so no exception sets are needed. The rule that
  `Wrappers` does not import `Model`, which the package enforced, becomes a
  convention.
- **No class prefix** (decided). Classes keep their Swift names. Checked on
  2026-11-05: of the 48 type names only `FileInfo` collides in the SDK
  headers (Carbon's `struct FileInfo` in `CarbonCore/Finder.h`, a compile
  error in anything that imports Foundation on macOS; the others compile
  against AppKit and UIKit), and none exists as a class in the macOS runtime
  with AppKit and AVFoundation loaded. `FileInfo` is renamed
  `FileSystemItemInfo`. Nothing in AppKit already responds to the methods and
  properties the view subclasses add (`update`, `setContent:`, `show:`,
  `addFillingSubview:` …). The check predates `ShareStatusBarView` and
  `NSStackView+SeparatedRows`; step 2 repeats both checks for them and against
  UIKit.
- **NSNotificationCenter replaces Observation** (decided). Views observe by
  selector, filtered on the posting object (no removal needed), and call
  their existing `update` method once by hand and then on each notification.
  Observation only re-ran a view for the properties it had read, so the
  notifications are split the same way: `Queue.didChangeNotification`;
  `Player.didChangeNotification` for `isPlaying` only, with nothing posted
  for `timeIndex`, which ticks twice a second and which no view reads;
  `MusicLibraryStore.libraryDidChangeNotification` and
  `.musicRootDirectoryDidChangeNotification` separately, so a root change
  does not reload the macOS outline and collapse it. `Player` drops the
  `Queue.onChange` block and observes `Queue.didChangeNotification` like the
  views; its `isMutatingQueue` guard stays.
- **`FolderChild` becomes a protocol** (decided), adopted by the `Folder` and
  `Track` classes. `Folder.children` holds folders and tracks directly.
- **Tests are XCTest**; Swift Testing is Swift-only. **`#Preview` blocks are
  dropped** as each file is translated, with the `import DeveloperToolsSupport`
  that serves them; the macro is Swift-only, and the launch skills remain the
  way to look at a view.
- **Swift interop annotations are scaffolding.** While Swift callers remain,
  headers carry `NS_SWIFT_NAME`, `NS_SWIFT_UI_ACTOR` and `NS_SWIFT_SENDABLE`
  where needed so Swift call sites keep their spelling and compile without
  new concurrency warnings. The last step deletes them. Nullability
  annotations and lightweight generics stay.
- **Out of scope.** The two Swift helpers under `.claude/skills/` stay Swift
  (decided). No behaviour, layout or requirement changes other than the
  language and the library form.

## Rework before translation

"Reshape" means reworked in Swift, in its own step, before that code is
translated. "Translate" means the rework happens as part of the translation
because Swift has nothing closer to offer.

| Swift feature | Where | Objective-C form | When |
|---|---|---|---|
| Enum with associated values, recursive | `FolderChild` (`.folder(Folder)`, `.track(Track)`) and every `switch` over it: `Queue.add`, `Folder.trackDescendants`, `FilesTreeNode`, `FolderChildCell.show`, `FolderTableViewController`; every test fixture | An `@objc` protocol `FolderChild` (`name`, `children`, `trackDescendants`) adopted by `Folder` and `Track`. Model switches become polymorphic calls; the three view sites that care which kind they have use a class check. Tests build children directly and compare child arrays through `isEqual`. | Reshape (step 4) |
| Value types (`struct`, `Hashable`, copy semantics) | `Track`, `Folder`, `QueuedTrack`, `MusicLibrary`, `LoadResult`, `MusicRootDirectory`; `FileInfo`, `ResolvedBookmark`, `FileSystemReal`, `PreferencesReal` | Final `NSObject` subclasses: read-only properties, designated initializers. Hand-written `isEqual`/`hash` on `Track`, `Folder` (deep, with a pointer fast path, a shallow hash and nil-safe `path` comparison; `FilesTableStackController.setRootFolder` relies on it to keep the navigation position across reloads) and `QueuedTrack`. | Reshape (steps 3 and 4) |
| `Codable` | Drag payload in `FolderChild+Pasteboard.swift`; `DemoEntry` in `LoadDemoMusicLibrary.swift` | Drag payload: `NSSecureCoding` and a keyed archive under the same pasteboard type. It must move first, because synthesized `Codable` stops working the moment `FolderChild` is a protocol; drags are app-local, so the format is free to change. `FolderChildTests`' JSON round trip becomes an `NSSecureCoding` round trip in `mcmusTests` beside the pasteboard tests. Demo data: `NSJSONSerialization` with explicit type checks. | Payload: reshape (step 4). Demo data: translate (step 8). |
| Observation (`@Observable`, `withObservationTracking`) | `Player`, `Queue`, `MusicLibraryStore`; `mcmus/Observing.swift`; every `observeChanges { }` call in the views | The notifications described above. They are delivered synchronously and are not coalesced, so each public model command posts once, after its state is settled (`Queue.add(_ children:)` appends once instead of looping; `apply` sets both properties, then posts). `Observing.swift` and its three tests are deleted; notification tests replace them. | Reshape (step 5). Must precede step 8: `withObservationTracking` sees nothing in an Objective-C object, so the UI would compile and silently stop updating. |
| Structured concurrency (`Task.detached`, `Task.isCancelled`, `await`) | `MusicLibraryStore.loadInBackground`, `changeMusicRootDirectory` and the `Result<MusicRootDirectory, any Error>` that `load` takes; its tests (`await store.loadTask?.value`, comparing tasks) | A load generation counter replaces `Task.isCancelled` and the test-visible `loadTask`; loads take a completion handler, which the Swift tests can still `await` and XCTest waits on with an expectation; the `Result` becomes a nullable `MusicRootDirectory` and an `NSError`. The mechanism itself becomes a utility-QoS global queue and `dispatch_async` to the main queue. | Seam: reshape (step 6). GCD: translate (step 12); writing GCD in Swift under default main-actor isolation would be throwaway friction. |
| Actor isolation and `Sendable` | `Player`, `Audio`, `AudioReal` (`isolated deinit`, `MainActor.assumeIsolated`), default main-actor isolation in the app target | Main-thread-only by convention; only fully immutable objects cross threads, and notifications are posted from the main queue only. `AudioReal`'s workarounds disappear. | Translate |
| Enum with associated values; nested types | `AudioFake.Call`; `FileSystemFake.Kind`, `.Entry` | A top-level class `AudioFakeCall` with factory methods and `isEqual`, so `audio.calls == [.play(…)]` still reads the same in the Swift tests; top-level `FileSystemFakeKind` and `FileSystemFakeEntry`. | Reshape (step 3) |
| Struct with value semantics as a test double | `FileSystemFake` (a struct holding a `Log` class so copies share a record; `mutating func add`) | A final class; the `Log` indirection goes away. | Reshape (step 3) |
| `throws`, `any Error`, Swift error types | `FileSystem` methods, `MusicRootDirectory.locate`, `LoadResult.errors`, `LoadDemoError`, `FileSystemFakeError`, `MissingDemoResource` | `NSError **` out-parameters (which Swift still imports as `throws`; a method returns `BOOL` or a nullable object and never fails without setting the error) and `NSArray<NSError *>`. Each Swift error type gets an error domain and codes. A Swift error keeps its type through `NSError` bridging only while the thrower is Swift, so tests match on domain, code and `userInfo`, not by casting. | Domains and test matching: reshape (step 3). Signatures: translate. |
| Names Objective-C cannot use | `FileInfo` (Carbon); `QueuedTrack.id` (`id` is the object type) | `FileSystemItemInfo`; `identifier`. `Identifiable` on `QueuedTrack` and `FolderChild` is a SwiftUI leftover and is removed. | Reshape (step 3) |
| Overloads | `Queue.add` (four overloads by argument type) | `add(_:)` taking any `FolderChild`, and `add(_ children:)`. | Reshape (step 4) |
| Default arguments | `Player.init`, `MusicLibraryStore.init`, `loadMusicLibrary`, `MusicRootDirectory.locate`, `PanelView.init`, `HairlineView.init`, `UIButton.bordered`, `FileSystemFake.init` and `add`, `PreferencesFake.init` | A convenience initializer or second method where a caller uses the default; dropped where none does. | Library: reshape (step 3). App views: translate. |
| Tuples, caseless enums as namespaces, enum initializers | `LowerLineWidths.split`, `MainMenu`, `PanelArrangement(fitting:)` | A C struct and function; a function returning the menu; an `NS_CLOSED_ENUM` (an `NS_ENUM` imports non-frozen, see the step 1 findings) and a C function. | Translate |
| Extensions on system types | `NSView`/`UIView.addFillingSubview`, `UIButton.bordered`, `NSStackView.headerOverBody`/`bodyOverFooter`, `NSPasteboard.PasteboardType.folderChild`, `[FolderChild].sortedByName` | Categories (the `NSStackView` one with class methods); a string constant; a function shared by the two loaders, which must ask for a stable sort. | Translate |
| Free functions | `loadMusicLibrary`, `loadDemoMusicLibrary` | C functions, same files. | Translate (step 8) |
| `@main` | Both `MCMusAppDelegate` files | One `mcmus/main.m` with a body per platform. macOS keeps today's explicit delegate creation before `NSApplicationMain`; iOS passes the delegate class name to `UIApplicationMain`. | Translate (step 17) |
| `#if os(…)` | Whole-file in every platform view; inside `FileSystem`, `FileSystemReal`, `FileSystemFake`, `MusicRootDirectory`, `MusicLibraryStore`, `AudioReal`, `MusicRootDirectoryTests` and `MusicLibraryStoreTests` | `#if TARGET_OS_OSX` / `TARGET_OS_IOS`, in both header and implementation. Twin files keep the `-iOS` / `-macOS` suffix on both. | Translate |
| Swift Testing | All 97 tests | XCTest: a suite's stored fixtures move to `setUp`, `#require` becomes an assertion with `continueAfterFailure = NO`, `async` tests wait on expectations. | Steps 11 and 13 |
| Swift-only workarounds | `EmptyStateView-iOS` (convenience-initializer dance around `init(configuration:)`) | A plain designated initializer. (The copy-mutate-assign of button and content-unavailable configurations stays: in Objective-C they are classes behind `copy` properties.) | Translate |

Smaller semantic differences to watch while translating:

- `URL(filePath:)` does not touch the disk but `+[NSURL fileURLWithPath:]`
  does, so `Track.url` uses `fileURLWithPath:isDirectory:`.
- Swift `String` compares by canonical equivalence and counts characters;
  `NSString` compares and counts UTF-16 units. This matters in `Track`'s
  extension stripping (use an anchored, case-insensitive, backwards range
  search rather than length arithmetic) and wherever paths are compared.
- `[nil isEqual:nil]` is `NO`; compare nullable properties explicitly.
- `Queue.queuedTracks` returns a copy; the table data sources keep the array
  across reloads.

## Conventions for the Objective-C code

- ARC, modules, `NS_ASSUME_NONNULL_BEGIN`/`END` in every header, lightweight
  generics, `instancetype`, `NS_DESIGNATED_INITIALIZER`. Inherited
  initializers a class does not support (`init`, `initWithFrame:`,
  `initWithCoder:`) are `NS_UNAVAILABLE`, replacing the
  `fatalError("init(coder:) is not supported")` idiom.
- One `Name.h` and `Name.m` per significant class, side by side, in the
  directory its Swift file occupies now. Small single-consumer classes
  (`FilesTreeDataSource`, `QueueTableDataSource`) stay private in their
  consumer's `.m`.
- Selectors are chosen so the Swift importer produces today's Swift names
  (`play:from:thenPlay:`, `initWithTrackName:albumName:artistName:path:`,
  `add:`); `NS_SWIFT_NAME` covers the rest. `Track.noAlbum`, `Track.noArtist`
  and `Folder.rootName` become class properties.
- Arrays and strings passed to initializers are copied; nothing hands out a
  mutable collection. Blocks capture `self` weakly wherever the Swift closure
  did.
- Comments follow `CLAUDE.md`: the existing "why" comments are carried over;
  comments that only explained a Swift workaround go with the workaround.

## Steps

### Phase 1: prepare, in Swift

1. **Spike, on a throwaway branch.** Prove the build mechanics with
   `PanelArrangement` (10 lines, compiled into both the app and `mcmusTests`,
   3 tests) before anything depends on them, and record the findings here:
   (a) the mixed app target: `PanelArrangement.h`/`.m`, bridging headers for
   the app and for `mcmusTests`, the exception-set edit, with the Swift
   `MainViewController-iOS.swift` and the Swift tests still compiling;
   (b) a SwiftPM C-family target with `publicHeadersPath: "."`, imported by
   the Swift 6 `Model` target and a Swift Testing test;
   (c) a static library target holding one class and one category, and an
   Objective-C XCTest logic bundle, in the pbxproj and the test plan on both
   destinations. Note whether quoted imports resolve across synchronized
   subfolders, whether `-ObjC` is needed, whether Xcode rewrote the schemes,
   and the executed test counts. Nothing from the branch is merged.

   **Findings (2026-11-06, Xcode 26.3, branch `spike/objc-build-mechanics`,
   commit 6c386a4; not merged).** `make check` and both launch skills pass
   on the branch; the iOS app arranges its panels correctly from the
   Objective-C `PanelArrangement` in both orientations.

   - *Header lookup needs no search paths.* Every quoted import resolved
     through `<target>-project-headers.hmap`, which Xcode fills with every
     header in every synchronized folder of the project, keyed by basename
     and regardless of owning target or subfolder: `mcmusTests`' map listed
     `PanelArrangement.h` (`mcmus/components/`), the spike library's class
     and its category header (in a `categories/` subfolder) and both
     bridging headers. So `#import "Player.h"` works from anywhere in the
     project once the library folders are synchronized groups, step 10's
     search paths are unnecessary, and header basenames must stay unique
     project-wide.
   - *(a) Mixed app target.* `PanelArrangement.h`/`.m` with
     `SWIFT_OBJC_BRIDGING_HEADER` set on the app (`mcmus/mcmus-Bridging-Header.h`)
     and on `mcmusTests` (`mcmusTests/mcmusTests-Bridging-Header.h`), and
     the "mcmus folder in mcmusTests target" exception entry changed from
     `.swift` to `.m` (the header needs no entry). The Swift view and the
     three Swift tests compiled unchanged, with the C function imported as
     `PanelArrangement(fitting:)` through
     `NS_SWIFT_NAME(PanelArrangement.init(fitting:))`. One surprise: an
     `NS_ENUM` from a bridging header imports as a non-frozen enum, so the
     exhaustive `switch` in `MainViewController-iOS.swift` warned that it
     "may have additional unknown values; this is an error in the Swift 6
     language mode"; `NS_CLOSED_ENUM` imports frozen and silences it.
   - *(b) SwiftPM C target.* `.target(name: "Spike", publicHeadersPath: ".")`
     with headers beside the `.m` files gave `module Spike { umbrella
     "<dir>" export * }`. The Swift 6 `Model` target imported it with
     `import Spike`, `ModelTests` imported it directly, and three Swift
     Testing tests ran. An `NS_SWIFT_SENDABLE` immutable class used from a
     nonisolated function and an `NS_SWIFT_UI_ACTOR` class used from a
     `@MainActor` function compiled without warnings in Swift 6 mode, so
     step 7 should not need `swiftLanguageModes: [.v5]`.
   - *(c) Static library and Objective-C test bundle.* A
     `com.apple.product-type.library.static` target and a
     `bundle.unit-test` target with no `SWIFT_*` settings, both with the
     app's multiplatform settings (`SDKROOT = auto`, the three platforms,
     `SKIP_INSTALL = YES`), the test bundle depending on the library through
     a `PBXContainerItemProxy`/`PBXTargetDependency` pair and linking
     `libspikeLib.a` from its Frameworks phase. Adding the bundle to
     `mcmus.xctestplan` was enough for it to run on both destinations; the
     shared schemes were not edited. **`-ObjC` is needed:** without it the
     category test failed with "unrecognized selector" while the class test
     passed, and `OTHER_LDFLAGS = -ObjC` on the test bundle fixed it, so any
     category in `mcmusBase` obliges every consumer to pass it. The Swift
     app also linked the library (Frameworks-phase entry plus dependency,
     `SpikeGreeter.h` imported from its bridging header) and the class
     landed in the app binary, which derisks step 10.
   - *Schemes.* `xcodebuild` never touched them. Opening the project in
     Xcode with the hand-written targets, waiting 45 s and quitting changed
     neither the schemes nor the pbxproj; the rewrite in the memory note
     comes from editing the pbxproj *while* Xcode has it open.
   - *Debug builds put the app's code in `MC Mus.debug.dylib`* beside a stub
     executable (`ENABLE_DEBUG_DYLIB`), so step 18's `otool -L` and symbol
     checks must inspect the dylib or the Release build.
   - *Executed tests* (macOS / iOS): `mcmusTests` 24 / 16, `WrappersTests`
     1 / 1, `ModelTests` 75 / 66 (72 / 63 plus the 3 spike tests), the spike
     bundle 2 / 2. Baseline on `main` the same day: 24 / 16, 1 / 1, 72 / 63.
2. **Requirements, baselines, project hygiene.** In `docs/requirements.md`
   replace "MC Mus shall use the Swift language." with the Objective-C
   equivalent. Record the baseline: executed tests per suite and platform
   (source counts: `ModelTests` 72, `WrappersTests` 1, `mcmusTests` 24; fewer
   run on iOS), and screenshots from `launch-mac-app` and `launch-ios-app`
   in normal and `--demo` mode (iOS in both orientations; macOS with a
   folder dragged to the queue). With the iOS app running in the simulator,
   repeat the class-name and selector checks against UIKit with `lldb`, and
   on both platforms run them for `ShareStatusBarView` and the
   `NSStackView+SeparatedRows` selectors, which postdate the first check. Fix
   two things that would undermine later steps: `mcmusTests/` is synchronized
   into the *app* target and excluded file by file, so a new test file
   compiles into the app until it is added to two exception sets (make the
   folder a synchronized group of the test target and delete both sets);
   and `mcmusTests/`, `mcmus.xctestplan` and the shared schemes are missing
   from `src_files` in the `Makefile`, so `make check` does not rerun for a
   test-only change. Move `mcmus/MusicLibraryStoreTests.swift` to
   `mcmusTests/`.

   **Baseline (2026-11-06, Xcode 26.3, after this step's hygiene changes).**
   Executed tests, macOS / iOS (iPhone 16e, iOS 18.4): `mcmusTests` 24 / 16,
   `WrappersTests` 1 / 1, `ModelTests` 72 / 63; the same counts as before the
   changes. Screenshots are in `docs/plans/2026-11-objective-c-rewrite-baseline/`:
   macOS normal, demo, and demo with "3 Doors Down" dragged to the queue;
   iOS normal and demo in portrait and landscape. Runtime checks, run under
   `lldb` in the launched apps with `objc_getClass`, `objc_getProtocol` and
   `class_respondsToSelector` (positive controls included): none of the 67
   type names, including `FileSystemItemInfo`, `AudioFakeCall`,
   `FileSystemFakeKind`, `FileSystemFakeEntry` and `FolderChildPasteboard`,
   is a class or protocol in either app's runtime (AppKit, UIKit and
   AVFoundation loaded), and none of the selectors the subclasses and
   categories add, now including `ShareStatusBarView`'s and
   `NSStackView+SeparatedRows`' class methods, already exists on its
   superclass. `mcmusTests/` is now a synchronized group of `mcmusTests` alone
   and its two exception sets are gone; `make check` reruns for changes to
   `mcmusTests/`, `mcmus.xctestplan` and the shared schemes.
3. **API tidy.** The "reshape (step 3)" rows of the table: names, default
   arguments, the fakes' shape, error domains and how tests match errors,
   and `FileSystemItemInfo`, `ResolvedBookmark`, `FileSystemReal` and
   `PreferencesReal` as final `NSObject` classes. Swift method names move to
   what the Objective-C will import as, so little `NS_SWIFT_NAME` is needed
   later.
4. **Model shape.** Pasteboard payload to `NSSecureCoding` first; then
   `FolderChild` as an `@objc` protocol and the model structs as final
   `NSObject` classes with `isEqual`/`hash`; `Queue.add` collapsed; `switch`
   sites rewritten. Test fixtures and comparisons are adapted here, once.
   Verify drag and drop on macOS and the iOS folder navigation surviving a
   reload.
5. **Observation to notifications.** As in the table and the decision above.
   Verify on both platforms: library load, add to queue, the play/stop
   button, Clear, the Settings path field, and the macOS outline keeping its
   expansion when the music folder is re-chosen.
6. **Store seam.** Load generation and completion handler; `Task.detached`
   stays as the mechanism.

### Phase 2: translate the library's sources, still a package

Each target moves to SwiftPM's C-family layout with headers beside sources
(`publicHeadersPath: "."`). Tests, and whatever is still Swift, do not change
in these steps beyond what the importer forces.

7. **`Wrappers`.** `Audio` and `AudioReal` are `NS_SWIFT_UI_ACTOR`;
   `FileSystem`, `Preferences` and the two value classes are
   `NS_SWIFT_SENDABLE`. If the Swift 6 `Model` target fights the imported
   annotations, set `swiftLanguageModes: [.v5]` on the remaining Swift
   targets rather than contort the headers. `AudioReal` and `FileSystemReal`
   have no unit tests, so this step is verified by launching both apps,
   loading a real library and playing a track.
8. **`Model`.** Now a mechanical translation of step 4's classes, plus
   `NSJSONSerialization` for the demo data, C functions for the loaders, and
   `Player` (`NS_SWIFT_UI_ACTOR`) and `Queue`.
9. **`WrappersTestSupport`.** The package now holds Objective-C sources and
   Swift tests.

### Phase 3: package to static library, then its tests

10. **Xcode targets replace the package.** `git mv` the five folders up from
    `Sources/` and `Tests/` to `mcmusBase/`. Add the `mcmusBase` and
    `mcmusBaseTestSupport` static library targets and the `mcmusBaseTests`
    bundle, all multiplatform like the app (`SDKROOT = auto`, the same
    `SUPPORTED_PLATFORMS` and deployment targets, `SKIP_INSTALL = YES`,
    explicit target dependencies). The app links `libmcmusBase.a`;
    `mcmusTests` and `mcmusBaseTests` link both libraries. Consumers find
    headers through Xcode's project header map (step 1 findings), so
    `#import "Player.h"` reads as it did in the package. The app,
    `mcmusTests` and `mcmusBaseTests` (all still Swift) each get a bridging
    header importing the library headers and lose their `import Model`,
    `import Wrappers` and `import WrappersTestSupport` lines. Delete
    `Package.swift`, `mcmusBase/.swiftpm/` and the package references in the
    pbxproj; point `mcmus.xctestplan` at `mcmusBaseTests`; check both schemes;
    update the code-location paragraphs of `docs/requirements.md`. No source
    file changes beyond imports. Executed test counts must match step 6.
11. **Library tests to XCTest**, one file at a time inside the mixed bundle,
    then remove the bundle's bridging header and Swift settings.

### Phase 4: translate the app

The app target is mixed from step 12 to step 17. Swift sees Objective-C
through `mcmus/mcmus-Bridging-Header.h`, which grows by one import per
translated header; twin headers guard themselves with `TARGET_OS_…`.

12. **Test-covered sources.** `PanelArrangement`, `LowerLineWidths`,
    `FolderChild+Pasteboard` (as `FolderChildPasteboard`) and
    `MusicLibraryStore` (`NS_SWIFT_UI_ACTOR`, and GCD in place of
    `Task.detached`). The membership exception entries change from `.swift`
    to `.m`, and `mcmusTests`' bridging header imports the new headers so its
    Swift tests keep running.
13. **`mcmusTests` to XCTest.** The bundle becomes pure Objective-C; delete
    its bridging header and Swift settings.
14. **Components.** `NSView+FillingSubview`, `UIView+FillingSubview`,
    `NSStackView+SeparatedRows`, `UIButton+Bordered`, `HairlineView`,
    `EmptyStateView` (both), `PanelView` (both), `ReadOnlyTextField`,
    `DropTargetView`.
15. **Queue panel.** `QueuedTrackCellView`, `QueueTableView`,
    `PlayerPanelView`, `QueuePanelViewController`, both platforms each.
16. **Files panel.** macOS: `FilesTreeNode`, `FilesTreeView`,
    `ShareStatusBarView`, `FilesPanelViewController`. iOS: `FolderChildCell`,
    `FolderTableViewController`, `FilesTableStackController`,
    `FilesPanelViewController`.
17. **Main, settings and the app shell.** `MainViewController` (both),
    `MainWindowController`, `SettingsWindowController`, `MainMenu`; then the
    macOS `MCMusAppDelegate` with the macOS body of `main.m`; then the iOS
    `MCMusAppDelegate` with the iOS body; then `MCMusSceneDelegate`, which
    reaches the app delegate through `MCMusAppDelegate.shared`, changing
    `UISceneDelegateClassName` in `Info.plist` from
    `$(PRODUCT_MODULE_NAME).MCMusSceneDelegate` to `MCMusSceneDelegate`. The
    Swift delegates are whole-file conditional, so neither platform ever
    links two `main`s. No Swift source remains in the app.
18. **Remove Swift from the build and finish.** Delete the bridging header,
    every `SWIFT_*` build setting, `ENABLE_PREVIEWS` and
    `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`. Delete
    the `NS_SWIFT_*` annotations. Rewrite the Swift examples in
    `docs/wrappers-for-testing.md` and the code-style example in `CLAUDE.md`
    in Objective-C; update the skill docs that mention Swift Testing and the
    memory notes. Run the acceptance checks below and `make release`. Move
    this plan to `docs/plans/completed/`.

## Risks

- **Silent test loss.** `make check` runs `xcodebuild -quiet`, so a test plan
  entry pointing at a deleted target, or an XCTest method not named
  `test…`, passes without running. Compare executed counts with the
  baseline after steps 10, 11 and 13. A ported test can also pass
  vacuously: break the implementation once per ported file and watch a test
  fail.
- **Flat namespaces.** Besides class names, a method or property added in a
  subclass can silently override a private superclass method of the same
  name, which Swift's non-`@objc` methods never could; categories on system
  classes carry the same risk. Hence the selector checks, and a look at each
  launch log for `Class … is implemented in both`.
- **Synchronous notifications.** A view's `update` now runs inside the model
  command that posted. `update` methods must not mutate the model, and
  commands post only once their state is consistent.
- **Static library linking.** The linker drops object files that define only
  categories unless consumers pass `-ObjC`; `mcmusBase` is planned to have
  none. `make release` overrides `CONFIGURATION_BUILD_DIR`, so the libraries
  land beside `MC Mus.app`; check the disk image still gets only the app.
- **Header lookup with synchronized groups** is settled by the spike: the
  project header map finds every header by basename across targets and
  subfolders, which also means a duplicate basename anywhere in the project
  silently shadows another.
- **Xcode rewrites shared schemes** when the pbxproj changes while the
  project is open. Quit Xcode for pbxproj edits (steps 2, 10, 12, 13, 18)
  and `git diff mcmus.xcodeproj/xcshareddata` afterwards; `mcmus-demo.xcscheme`
  references the test plan too.
- **Lost compiler checks.** No exhaustive `switch` over `FolderChild`, no
  optional unwrapping, no `Sendable` checking. Nullability annotations, the
  static analyzer settings already enabled in the project, and the tests
  take their place.
- **`AudioReal` teardown** loses `isolated deinit`, so `dealloc` may run off
  the main thread. The one instance lives as long as the app; say so in a
  comment rather than add machinery.
- **Sandboxed test builds.** `xcodebuild test` signs with a whole-disk read
  exception, so the security-scoped bookmark path is checked on a plain
  build after steps 7, 8 and 12, as today.

## Verification

- `make check` after every step: both platforms, all suites.
- `launch-mac-app --build` and `launch-ios-app --build`, normal and `--demo`,
  after every step that touches code the app runs; screenshots compared with
  the step 2 baselines; launch logs checked for Auto Layout conflicts and
  Objective-C runtime warnings.
- Behaviour checks, at the steps named above and again at the end: add a
  folder and a track to the queue; play, stop, back, next and Clear against
  the bundled demo clip, watching the queue shrink as tracks end; drag from
  the files tree to the queue on macOS; toggle the share switch and watch its
  status text; choose a music folder in Settings, quit and relaunch to
  confirm the bookmark; rotate on iPhone.
- Acceptance at step 18: `git ls-files '*.swift'` lists only the two skill
  helpers; `otool -L` on the built macOS and iOS executables shows nothing
  under `/usr/lib/swift`; neither app bundle contains a `libswift*.dylib`;
  `grep -r NS_SWIFT_ mcmus mcmusBase mcmusTests` prints nothing; `make release`
  produces the Release build and disk image.
