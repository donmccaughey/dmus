---
name: launch-mac-app
description: Launch the Dmus macOS Debug build from the command line, wait for its window, screenshot it, and quit it cleanly, in normal or --demo mode. Use this whenever you need to run, launch, open, smoke-test, or screenshot the Mac app to verify a change, including when the `run` skill or a plan's verification step calls for running the app. Encodes launch-flag ordering and window-lookup pitfalls that otherwise make a working build look hung.
allowed-tools: Bash(.claude/skills/launch-mac-app/scripts/launch-mac-app.sh:*), Bash(xcodebuild:*), Bash(screencapture:*), Bash(kill:*), Bash(pgrep:*)
---

Use the bundled script rather than hand-rolling `open` and AppleScript. It
handles every pitfall listed below.

```bash
.claude/skills/launch-mac-app/scripts/launch-mac-app.sh [--demo] [--build] [--screenshot PATH] [--keep] [--wait SECONDS]
```

Typical verification of a change, both library modes:

```bash
S=<scratchpad directory>
.claude/skills/launch-mac-app/scripts/launch-mac-app.sh --build --screenshot "$S/real.png"
.claude/skills/launch-mac-app/scripts/launch-mac-app.sh --demo --screenshot "$S/demo.png"
```

Then view each PNG with the Read tool. The script quits the app before it
exits unless `--keep` is given, and prints the PID so only that instance is
ever killed. It exits non-zero, with the app's stderr, if the process dies or
no window appears within the wait.

Run `--build` once per source change. Without it the script uses whatever
Debug build is already in DerivedData, which may be stale.

## Why the script does what it does

Each of these cost real time when discovered, so do not work around the
script in ways that reintroduce them.

- **Flag order.** `-ApplePersistenceIgnoreState YES` goes before `--demo`.
  With `--demo` first, AppKit's argument parser swallows the pair: the process
  stays alive with an idle main thread and never shows a window. It looks like
  a hang or a regression in the code under test and is neither.
- **Window lookup.** System Events (`osascript`) needs an Accessibility grant
  and blocks forever on the permission prompt when run unattended. The script
  compiles a tiny Swift tool around `CGWindowListCopyWindowInfo`, which needs
  no permission, and polls it by PID.
- **Process name.** The product is `Dmus`, not `dmus`. `pkill -x dmus` and
  `tell process "dmus"` silently match nothing.
- **Launch the binary, not the bundle.** Running
  `Dmus.app/Contents/MacOS/Dmus` directly gives the PID as `$!` and captures
  stderr to a log. `open -n` loses both and needs a `pgrep` that may pick up
  the user's own running copy of the app.
- **Screenshots by window ID.** `screencapture -l <id>` captures only that
  window. Never capture the whole screen.
- **Persistence state.** `-ApplePersistenceIgnoreState YES` stops NSWindow
  state restoration from replaying the last window frame, so first-launch
  size and position are what the code specifies.

## Checking the result

- Normal mode: the Files panel lists folders from `~/Music`.
- Demo mode: the Files panel lists artist folders from the bundled
  `demo-data.json` (starting with "3 Doors Down").
- Either mode with an empty Files panel after a few seconds means the load
  result carried an error; check the log path the script prints.

If the user already has Dmus open, leave it alone. The script only ever
signals the PID it launched.
