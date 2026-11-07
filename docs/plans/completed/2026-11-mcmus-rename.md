# Rename Dmus to MC Mus

## Context

The name "Dmus" is taken, so the app is now "MC Mus". Commit `0351778` already
changed the bundle ID to `cc.donm.mcmus` (including the pasteboard UTI
`cc.donm.mcmus.folder-child`, the test bundle ID and the skill files that
mention the bundle ID) and set `INFOPLIST_KEY_CFBundleDisplayName = "MC Mus"`.
Everything else still says `dmus`/`Dmus`: displayed strings, Swift types, the
product name, Xcode targets and schemes, the Swift package, the project, the
source directories, assets, docs and skills.

## Decisions

- **Product name `MC Mus`**, giving `MC Mus.app` and the executable `MC Mus`.
  On macOS the Finder, Dock and Launchpad name comes from the bundle filename:
  a non-localized `CFBundleDisplayName` that differs from the filename is
  ignored (`Visual Studio Code.app` on this Mac declares the display name
  "Code" and Finder shows "Visual Studio Code"). So the space has to be in the
  product name, and paths in scripts and the Makefile must be quoted.
- **Identifier `mcmus`** replaces `dmus` everywhere lowercase `dmus` is used
  today: targets, schemes, package, directories and file names. Swift types
  use the prefix `MCMus`.
- **`docs/plans/`**: update the pending `2026-11-objective-c-rewrite.md` so it
  stays executable; leave `docs/plans/completed/` as history.
- **Repo and root directory** are renamed by hand, outside this plan. Skill
  files that name the GitHub repo (`donmccaughey/dmus`) change to
  `donmccaughey/mcmus` on the assumption that is the new slug.
- **One commit per step**, so each is reviewable on its own. The pre-commit
  hook runs `make check` on every commit.
- **Quit Xcode before starting.** An externally edited pbxproj makes Xcode
  rewrite the shared schemes, discarding concurrent scheme edits. If it stays
  open, check `git diff dmus.xcodeproj/xcshareddata` after each pbxproj step.
- **Left alone on purpose:** `docs/plans/completed/*`; the two historical
  comment examples `.claude/skills/investigate-issue/comment-example.md` and
  `.claude/skills/plan-issue/plan-comment-example.md`, which quote code that no
  longer exists; and the binary `dmus-app-icon-light.png`, whose embedded
  metadata happens to match `dmus`.

## Steps

### 1. Displayed strings

Strings the user sees. No file renames.

- `dmus/main/MainMenu.swift`: app menu title `"MC Mus"`, `"About MC Mus"`,
  `"Hide MC Mus"`, `"Quit MC Mus"`.
- `dmus/main/MainWindowController.swift`: `window.title = "MC Mus"`.
- `dmus/settings/SettingsWindowController.swift`: `"MC Mus Settings"`.
- `dmus/DmusSceneDelegate.swift`: `windowScene.title = "MC Mus"`.
- `dmus/Info.plist`: `UTTypeDescription` becomes `MC Mus folder or track`.

AppKit titles the application menu from `CFBundleName`, which is
`$(PRODUCT_NAME)`, so the menu bar keeps showing "Dmus" until step 3 even
though the `NSMenuItem` title changes here.

### 2. Swift type names

- `DmusAppDelegate` becomes `MCMusAppDelegate` in
  `dmus/DmusAppDelegate-iOS.swift`, `dmus/DmusAppDelegate-macOS.swift` and
  `dmus/DmusSceneDelegate.swift`.
- `DmusSceneDelegate` becomes `MCMusSceneDelegate` in
  `dmus/DmusSceneDelegate.swift` and `dmus/DmusAppDelegate-iOS.swift`.
- `git mv` the three files to `MCMusAppDelegate-iOS.swift`,
  `MCMusAppDelegate-macOS.swift` and `MCMusSceneDelegate.swift`. They are in a
  file-system-synchronized group, so the pbxproj does not change.

### 3. Product name `MC Mus`

- `dmus.xcodeproj/project.pbxproj`: `PRODUCT_NAME = "MC Mus"` in the Debug and
  Release configurations of the app target; the product `PBXFileReference`
  becomes `path = "MC Mus.app"` with its comment.
- Both schemes in `dmus.xcodeproj/xcshareddata/xcschemes/`:
  `BuildableName = "Dmus.app"` becomes `"MC Mus.app"` (three occurrences each).
- `Makefile`: add `product = MC Mus` and `app = $(release_dir)/$(product).app`
  and quote `"$(app)"` in recipes. A make target name cannot contain a space,
  so replace the `$(TMP)/Dmus-$(ver).dmg` target with a `$(TMP)/release.stamp`
  target that runs `scripts/make-dmg.sh "$(app)" $(TMP)` and touches the
  stamp; `release` depends on the stamp. Update the "use a stamp file"
  comment. `scripts/make-dmg.sh` already derives every name from
  `CFBundleName` and quotes `$app`, so it produces `MC Mus-1.0.dmg` unchanged.
- `.claude/skills/launch-mac-app/scripts/launch-mac-app.sh` and
  `.claude/skills/launch-ios-app/scripts/launch-ios-app.sh`: the
  `awk '/ FULL_PRODUCT_NAME =/{print $3}'` extraction splits on the space and
  yields `MC`. Change both `awk` calls (and the `BUILT_PRODUCTS_DIR` ones
  beside them) to take everything after `" = "`, for example
  `awk -F' = ' '/ FULL_PRODUCT_NAME =/{print $2}'`. The scripts already quote
  `$app` and `$binary`.
- `.claude/skills/launch-mac-app/SKILL.md`: the process name is now `MC Mus`
  with a space: `pkill -x "MC Mus"`, `tell process "MC Mus"`,
  `MC Mus.app/Contents/MacOS/MC Mus`, window `"MC Mus Settings"`.
- `.claude/skills/launch-ios-app/SKILL.md`: `Unknown client: MC Mus`,
  `pgrep -f "MC Mus.app/MC Mus"`.
- `.claude/skills/investigate-issue/SKILL.md`: `.../MC Mus.app`,
  `quit app "MC Mus"`.

### 4. Xcode targets, schemes and test plan

`dmus` becomes `mcmus` and `dmusTests` becomes `mcmusTests`.

- `project.pbxproj`: `name` and `productName` of both targets; the test
  product reference `path = dmusTests.xctest` becomes `mcmusTests.xctest`;
  the `/* dmus */`, `/* dmusTests */`, `"dmus"` and `"dmusTests"` comments on
  the targets, configuration lists and exception sets.
- Schemes: `git mv dmus.xcscheme mcmus.xcscheme` and
  `git mv dmus-demo.xcscheme mcmus-demo.xcscheme`; inside, `BlueprintName`
  `"dmus"` becomes `"mcmus"` and `"dmusTests"` becomes `"mcmusTests"`, and
  `BuildableName = "dmusTests.xctest"` becomes `"mcmusTests.xctest"`.
  `BlueprintIdentifier` values are object IDs and stay.
- `dmus.xctestplan`: `"name" : "dmusTests"` becomes `"mcmusTests"`.
- `Makefile`: `-scheme dmus` becomes `-scheme mcmus` (four places).
- Launch scripts: `-scheme dmus` becomes `-scheme mcmus` (two places each).
- `.claude/skills/investigate-issue/SKILL.md`: scheme and test target names.

### 5. Swift package `dmusBase` to `mcmusBase`

- `git mv dmusBase mcmusBase` (the ignored `.build/` moves with it; harmless).
- `mcmusBase/Package.swift`: `name: "mcmusBase"`, products `"mcmusBase"` and
  `"mcmusBaseTestSupport"`. The module names `Model`, `Wrappers`,
  `WrappersTestSupport` and the test targets do not change, so no `import`
  statements change.
- `git mv mcmusBase/.swiftpm/xcode/xcshareddata/xcschemes/dmusBase.xcscheme
  mcmusBase.xcscheme`; inside, `BlueprintIdentifier`, `BuildableName` and
  `BlueprintName` `dmusBase` become `mcmusBase` (two blocks).
- `project.pbxproj`: the package `PBXFileReference` `path = dmusBase` becomes
  `mcmusBase`; the six `XCSwiftPackageProductDependency` entries
  `productName = dmusBase` and `dmusBaseTestSupport` become `mcmusBase` and
  `mcmusBaseTestSupport`; the matching comments in `PBXBuildFile`,
  `PBXTargetDependency`, `packageProductDependencies` and the group listing.
- `dmus.xctestplan`: `"containerPath" : "container:dmusBase"` becomes
  `mcmusBase` (two places).
- `Makefile`: `package_files = $(shell find mcmusBase ...)`.

### 6. Xcode project and test plan files

- `git mv dmus.xcodeproj mcmus.xcodeproj` and
  `git mv dmus.xctestplan mcmus.xctestplan`.
- `project.pbxproj`: the test plan `PBXFileReference` `path = mcmus.xctestplan`
  with its comment; the `Build configuration list for PBXProject "mcmus"`
  comment.
- Both schemes: every `ReferencedContainer = "container:mcmus.xcodeproj"` and
  `reference = "container:mcmus.xctestplan"`.
- `mcmus.xctestplan`: `"containerPath" : "container:mcmus.xcodeproj"`.
- `Makefile`: `-project mcmus.xcodeproj` (four places) and `project_files`.
- Launch scripts: `"$project_dir/mcmus.xcodeproj"` (two places each).
- `.claude/skills/investigate-issue/SKILL.md` and
  `.claude/skills/plan-issue/SKILL.md`: `mcmus.xcodeproj/project.pbxproj`.

The DerivedData folder name changes with the project name; the launch skills
always build first (`--build`), so nothing else is needed.

### 7. Source directories and entitlements

- `git mv dmus mcmus`, `git mv dmusTests mcmusTests`,
  `git mv mcmus/dmus-iOS.entitlements mcmus/mcmus-iOS.entitlements` and
  `git mv mcmus/dmus-macOS.entitlements mcmus/mcmus-macOS.entitlements`.
- `project.pbxproj`: synchronized root groups `path = dmus` becomes `mcmus`
  and `path = dmusTests` becomes `mcmusTests`, with their comments and the
  exception-set comments; `CODE_SIGN_ENTITLEMENTS =
  "mcmus/mcmus-iOS.entitlements"` and the `[sdk=macosx*]` variant in Debug and
  Release; `INFOPLIST_FILE = mcmus/Info.plist` in Debug and Release.
- `Makefile`: `app_files = $(shell find mcmus ...)`.
- `.claude/skills/investigate-issue/SKILL.md` and
  `.claude/skills/plan-issue/SKILL.md`: `mcmus/...` paths.

### 8. Image assets

- `git mv` `assets/dmus-app-icon-dark.png`, `assets/dmus-app-icon-light.png`,
  `assets/dmus-logo-256.png` and `assets/dmus-logo-256.pxd` to
  `assets/mcmus-...`.
- `git mv` `mcmus/AppIcon.icon/Assets/dmus-app-icon-{dark,light}.png` to
  `mcmus-app-icon-{dark,light}.png`; in `mcmus/AppIcon.icon/icon.json` update
  the two `image-name` and two `name` values.
- `README.md`: logo path and alt text.

### 9. Documentation and prose

- `docs/requirements.md`: every `dmus` and `Dmus` naming the app becomes
  `MC Mus` ("MC Mus shall...", "On macOS, MC Mus shall...", "The MC Mus
  project shall..."). The introduction becomes: requirements for "MC Mus", a
  cross-platform, offline music player, dropping the capitalization aside. The
  app name requirement becomes: MC Mus shall use "MC Mus" wherever the app
  name is displayed: window title, app icon, menus, etc. (fixing "name name").
  Menu items: the app ("MC Mus") menu, "About MC Mus", "Hide MC Mus", "Quit MC
  Mus". Directory and package names in Project organization and Code
  locations: `mcmus/`, `mcmusBase`, `mcmus/files/`, `mcmusTests/` and so on.
- `CLAUDE.md` and `README.md`: title `# MC Mus`.
- Skill prose: the `SKILL.md` descriptions and body text of `investigate-issue`,
  `plan-issue`, `launch-ios-app` and `launch-mac-app` change `Dmus` to
  `MC Mus` and `donmccaughey/dmus` to `donmccaughey/mcmus`; the launch
  scripts' header comments and their cache directories `dmus-launch-*-app`
  become `mcmus-launch-*-app`.
- `docs/plans/2026-11-objective-c-rewrite.md`: `Dmus` becomes `MC Mus` in
  prose; `dmus/`, `dmusBase`, `dmusTests`, `dmus.xcodeproj`,
  `DmusAppDelegate`, `DmusSceneDelegate`, `libdmusBase.a` and
  `dmus-Bridging-Header.h` take the new names; `Dmus-Swift.h` becomes
  `MC_Mus-Swift.h`, since Xcode derives the module name by replacing the space
  with an underscore.

### 10. Housekeeping outside the repo

No commit. Claude's memory files under
`~/.claude/projects/-Users-donmcc-Developer-Don-dmus/memory/` record the
process name `Dmus`, `pgrep -x Dmus`, `dmus/...` paths, `DmusAppDelegate` and
`dmus.xcodeproj`; update them. Claude Code keys that directory to the project
path, so after the root directory is renamed to `mcmus`, move
`~/.claude/projects/-Users-donmcc-Developer-Don-dmus` to
`-Users-donmcc-Developer-Don-mcmus` to keep the memories.

## Verification

- After every step: `make check` (also run by the pre-commit hook), which
  runs `mcmusTests`, `ModelTests` and `WrappersTests` on the iOS simulator and
  on macOS.
- After steps 4 through 7: `xcodebuild -list -project mcmus.xcodeproj` shows
  the targets `mcmus` and `mcmusTests` and the schemes `mcmus` and
  `mcmus-demo`; `git diff --stat` of the schemes shows only the intended
  edits.
- After step 3 and again at the end: launch the Mac app with the
  `launch-mac-app` skill (`--build --demo --screenshot`). The title bar reads
  "MC Mus"; through System Events, `tell process "MC Mus"` lists the menu bar
  items "MC Mus", "File", "Edit" and "Window", and the app menu holds "About
  MC Mus", "Hide MC Mus" and "Quit MC Mus"; "Settings..." opens a window titled
  "MC Mus Settings"; `ps -o comm=` on the pid ends in
  `MC Mus.app/Contents/MacOS/MC Mus`.
- After step 3: `make release` produces `tmp/MC Mus-1.0.dmg` whose volume is
  named "MC Mus" and contains `MC Mus.app`, exercising the quoted Makefile
  paths and `make-dmg.sh`.
- At the end: launch the iOS app with the `launch-ios-app` skill
  (`--build --demo --screenshot`); `xcrun simctl listapps` shows
  `CFBundleDisplayName = "MC Mus"` and `CFBundleName = "MC Mus"`.
- At the end: `git grep -n -i dmus` lists only the intentional leftovers:
  `docs/plans/completed/`, the two comment example files and the binary icon.
