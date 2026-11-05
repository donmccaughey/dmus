---
name: launch-ios-app
description: Launch the Dmus iOS Debug build on a simulator from the command line, set its orientation, screenshot the device upright, and terminate it cleanly, in normal or --demo mode. Use this whenever you need to run, launch, open, smoke-test, or screenshot the iOS app to verify a change, including when the `run` skill or a plan's verification step calls for running the app on iOS. Encodes the device-resolution, rotation and screenshot-orientation pitfalls that otherwise waste a session.
allowed-tools: Bash(.claude/skills/launch-ios-app/scripts/launch-ios-app.sh:*), Bash(xcodebuild:*), Bash(xcrun simctl:*), Bash(osascript:*), Bash(screencapture:*), Bash(sips:*), Bash(pgrep:*)
---

Use the bundled script rather than hand-rolling `simctl` and AppleScript. It
handles every pitfall listed below.

```bash
.claude/skills/launch-ios-app/scripts/launch-ios-app.sh [--demo] [--build] [--screenshot PATH] [--landscape] [--udid UDID] [--keep] [--wait SECONDS]
```

Typical verification of a change, both library modes and both orientations:

```bash
S=<scratchpad directory>
.claude/skills/launch-ios-app/scripts/launch-ios-app.sh --build --screenshot "$S/empty-portrait.png"
.claude/skills/launch-ios-app/scripts/launch-ios-app.sh --demo --screenshot "$S/demo-portrait.png"
.claude/skills/launch-ios-app/scripts/launch-ios-app.sh --landscape --screenshot "$S/empty-landscape.png"
.claude/skills/launch-ios-app/scripts/launch-ios-app.sh --demo --landscape --screenshot "$S/demo-landscape.png"
```

Then view each PNG with the Read tool. The script terminates the app before
it exits unless `--keep` is given, and prints the device UDID, the app's PID,
the stderr log path and the simulator window's frame (`window=x,y,w,h` in
screen points). It exits non-zero, with the app's stderr, if the process
dies, and non-zero if it cannot reach the requested orientation.

Run `--build` once per source change. Without it the script installs
whatever simulator Debug build is already in DerivedData, which may be stale.

The default device is the iOS 18.4 iPhone 16e that `make check` uses. Xcode
26 builds against the iOS 26 SDK, and on an iOS 26 simulator the system
components take the new design, so compare layouts on 18.4. `--udid` picks
another device (from `xcrun simctl list devices available`); the iOS 18.4
iPad Pro 11-inch is `2EFD3632-0EFD-4BEE-B638-7AA561250E90`.

## Why the script does what it does

- **Device by UDID.** A `name=iPhone 16e` destination is ambiguous because
  several runtimes have one; `resolve-device.py` picks the UDID by name and
  OS from `simctl list -j`, and the destination also names `arch=` so
  xcodebuild stops warning about the Rosetta variant.
- **Each run starts fresh.** `simctl terminate` before `install` and
  `launch`, so the queue is empty and the new binary is the one running.
- **Log from the unified log.** `simctl launch --stderr=<path>` never
  creates its file (Xcode 26), so after the settle time the script writes
  the app's error- and fault-level lines, plus anything mentioning
  "constraint", from `simctl spawn <udid> log show` into the log it prints.
  Two lines are always there and are simulator noise (a libxpc "assertion
  failed" and a CFBundle "No factory registered"), as are two
  app_launch_measurement "Failed to send CA Event" lines on some launches
  and an AXRuntimeCommon "Unknown client: Dmus" once System Events has
  clicked in the app; an Auto Layout conflict would appear as "Unable to
  simultaneously satisfy constraints".
  `launch` prints the host PID, which `kill -0` can watch.
- **Orientation is read from the screen.** `simctl` cannot report or set
  orientation, and `simctl io screenshot` always writes the framebuffer in
  physical portrait dimensions with the content drawn rotated, so the image
  size says nothing. `screen-orientation.swift` (compiled on first use into
  `$TMPDIR/dmus-launch-ios-app`) finds the home indicator instead: bottom
  edge is portrait, left edge is landscape left, right edge is landscape
  right. The script rotates the saved screenshot upright with `sips -r`.
- **Rotation is Simulator.app's ⌘← / ⌘→.** Simulator has no scripting
  interface, so the script activates it, raises this device's window with
  `AXRaise` (another booted device's window would otherwise take the keys)
  and sends `key code 123/124 using command down`. Rotate Right cycles
  portrait → landscape right → upside down → landscape left; iPhone apps
  refuse upside down and keep their last landscape layout there while the
  window turns portrait-shaped, so the script checks the window's shape as
  well as the screen and rotates back out of that state. `--landscape` means
  landscape left (one ⌘← from portrait); without it the script restores
  portrait, whatever a previous run or a manual rotation left behind.
- **Window name.** Simulator names the window `"iPhone 16e – iOS 18.4"`
  with an en dash and the OS version; query `name of windows` if it is not
  found.

## Checking the result

- Normal mode: there is no way to put music on an iOS device yet, so the
  library is empty and the Files panel shows "No music" / "The music library
  is empty." with a disabled "Find"; the Queue panel shows "No tracks" /
  "The queue is empty." with a disabled "Clear".
- Demo mode: the Files panel is a navigation bar titled "Files" with an
  enabled "Find" over artist folders starting with "3 Doors Down"; the
  queue is empty until something is added.
- Portrait stacks the panels, landscape puts them side by side.
- Demo mode with an empty Files panel after a few seconds means the load
  result carried an error; check the log path the script prints.

## Driving the launched app

`simctl` cannot tap. Taps are System Events `click at {x, y}` in screen
points on the raised simulator window:

```applescript
tell application "Simulator" to activate
tell application "System Events" to tell process "Simulator"
    perform action "AXRaise" of window "iPhone 16e – iOS 18.4"
    click at {384, 306}
end tell
```

Raise the window first or another booted simulator's window may take the
click (stray clicks have opened Health on the iPad simulator). Map device
points through the window frame the script prints; the window moves and
changes shape on rotation, so re-query it (`get {position, size} of window
...`) before each batch of taps.

- Device points are screenshot pixels divided by 3 on the iPhone 16e
  (1170×2532 px for 390×844 pt).
- With the window at 100% scale (Simulator's Window > Physical Size), the
  device screen sits at offset (31, 84.5) points inside the portrait window
  and (22, 93) inside the landscape one, one screen point per device point:
  `screen x = window x + 31 + device x`, `screen y = window y + 84.5 +
  device y` in portrait. Re-derive the offsets if the window scale changes:
  `screencapture -x -R x,y,w,h` of the window frame (2 px per point) and
  measure the screen's top-left corner.
- Tapping the "+" on the first folder row of a demo library at window
  (9, 109) is `click at {384, 306}` in portrait and `{407, 268}` in
  landscape; the chevron on that row is `{410, 306}` in portrait.
- Scroll a list with a CGEvent left-mouse drag (mouse down, ~30 dragged
  steps, mouse up); scroll-wheel events posted over the simulator are
  ignored. Keep posting dragged events at the end point for half a second
  before the mouse up so the list does not coast, and expect it to move
  about 1.7 times the drag distance.
- In portrait with a filled queue the player buttons are at device
  (112, 514), (195, 514) and (278, 514) and "Clear" is at (350, 455); with
  the window at (9, 109) play is `click at {235, 707}`. The queue table
  starts at device y 548, so a drag meant to scroll it has to start below
  that.
- Dark mode: `xcrun simctl ui <udid> appearance dark` (and `light` after).
  Switch after the script returns, with `--keep`, and take the screenshot
  with `simctl io` (rotating a landscape one with `sips -r 270`): the dimmed
  home indicator is too faint in dark mode for the script to read the
  orientation, so a launch in dark mode fails with "could not rotate".
- The iPad app switcher (to read the scene title or open a second window)
  is `key code 4 using {control down, shift down, command down}` on the
  raised iPad window; clicking Simulator's Device > App Switcher menu item
  through System Events toggles it too.
- The iPad Pro 11-inch window is scaled: the device screen starts at
  (43, 95) points inside the window and one device point is 0.76 screen
  points, in both orientations. Wait a second after `AXRaise` before a
  `click at`, or the click only raises the window.
- The iPad multitasking control ("•••" at the top centre of an app) and
  everything it opens ignore `click at`; use the held CGEvent press. It
  shows Full Screen, Split View and Slide Over, and a shelf along the bottom
  with one thumbnail per Dmus window plus "New Window". The shelf also
  lists windows saved from earlier runs, which only connect when chosen.
  After Split View, pick the second app from the Home screen or the Dock.
- A simulator that last ran the SwiftUI build keeps the scene session
  SwiftUI persisted, so UIKit restores `SwiftUI.AppSceneDelegate` as the
  scene delegate without asking the app delegate: the screen is black, the
  app crashes in `AppSceneDelegate.sceneItem()` when sent to the
  background, and the script fails with "could not rotate … (now unknown)".
  On iOS 18.4 this cleared after two launches; on iOS 26.1 it survives
  relaunches, reinstalls and a bundle version change. `simctl uninstall`
  and rerun.
- Every view frame in the running app:
  `lldb -p $(pgrep -f Dmus.app/Dmus) --batch -o 'expr -l objc -O -- [[[UIApplication sharedApplication] keyWindow] recursiveDescription]' -o detach -o quit`.
- `click at` fires buttons (the row "+" and chevron, Back, Find, Clear, the
  player controls) but is too brief to select a table row, in the UIKit
  folder tables. To tap a row, post a CGEvent left mouse down at the point,
  hold about 0.1 s, then mouse up.
- Track rows have only a "(+)", where the folder rows' chevron is: window
  (9, 109) puts the first one at `click at {404, 306}` in portrait.
