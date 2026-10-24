# Example plan comment

This is the tone and shape to aim for: a plan someone else could carry out from
the comment alone, with `path:line` references into the code at the named commit,
code snippets only where the exact form matters, and verification steps that
mirror the issue's desired behavior. Adapt the sections to the issue; drop a
section that has nothing to say.

---

Plan to fix this, against commit `934c9d8`.

## Context

Every behavior in the report comes from `WindowGroup("Dmus")` in
`dmus/dmusApp.swift:25`, as the investigation above found. On macOS a
`WindowGroup` supplies the "New <title> Window" command, allows any number of
instances, enables native window tabbing, and leaves the process running with no
windows because there is no app delegate.

`docs/requirements.md:140` says only that macOS "shall show a main window on
launch", so the desired behavior needs a requirement before it needs code.

## Changes

### 1. `docs/requirements.md`

Add after the two-panel requirement under "User interface":

> On macOS, dmus shall only allow one main window without tabs, and shall quit
> the app when the main window is closed.

### 2. `dmus/dmusApp.swift`: use a `Window` scene on macOS

`Window` (macOS 13+) is SwiftUI's single-instance scene: it never gets a "New
Window" command and only one instance can exist. It does not exist on iOS, so the
scene body is branched and the shared content moves into a private `mainView`
property:

```swift
var body: some Scene {
    #if os(macOS)
    Window("Dmus", id: "main") {
        mainView
    }
    .defaultSize(width: 900, height: 600)
    #else
    WindowGroup("Dmus") {
        mainView
    }
    #endif
}
```

### 3. `dmus/dmusApp.swift`: add a macOS app delegate

SwiftUI has no scene-level API for "quit when the last window closes" or "no
tabbing", so a minimal `NSApplicationDelegate` is added under `#if os(macOS)` and
attached with `@NSApplicationDelegateAdaptor`. It sets
`NSWindow.allowsAutomaticWindowTabbing = false` in
`applicationWillFinishLaunching`, which must run before AppKit builds the View
menu, and returns `true` from `applicationShouldTerminateAfterLastWindowClosed`.

### 4. `dmus/dmusApp.swift`: reword the `init()` comment

The comment at line 12 justifies loading in `init()` with "if macOS opens more
than one window", which stops being true. Reword it to the reason that holds:
the load starts at launch, independent of view lifecycle.

## Verification

Build and launch the macOS Debug app, then drive it with `osascript` (System
Events):

1. The File menu has no "New Dmus Window" item.
2. The View menu has no "Show Tab Bar" or "Show All Tabs" items.
3. The window count is 1, the title is "Dmus", and Cmd+N produces nothing.
4. Cmd+W closes the window and `pgrep -x Dmus` finds no process afterwards.

Also build for the iOS Simulator (a device on iOS 18 or later) to confirm the
branched scene body compiles there; iOS behavior is unchanged.

## Out of scope

No commit is made and the issue is not closed as part of carrying out this plan.
