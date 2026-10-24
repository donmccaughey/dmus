---
name: investigate-issue
description: Read a Dmus GitHub issue by number, verify or reproduce it, and post the steps and result as a comment on the issue. Use when asked to investigate, verify, confirm, or reproduce an issue.
argument-hint: [issue-number]
disable-model-invocation: true
allowed-tools: Bash(gh issue view:*), Bash(gh issue comment:*), Bash(gh api:*), Bash(xcodebuild:*), Bash(xcrun simctl:*), Bash(open:*), Bash(osascript:*), Bash(screencapture:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git status:*), Bash(ls:*), Bash(mdls:*), Bash(GetFileInfo:*), Bash(sw_vers:*)
---

Investigate GitHub issue #$ARGUMENTS in `donmccaughey/dmus` and post a comment on
it describing how it was verified or reproduced and what was found. This is an
investigation only: do not edit source files, do not close, label, or retitle the
issue, and do not propose a fix beyond a one-line pointer to the responsible code.

## 1. Fetch the issue

```bash
gh issue view $ARGUMENTS --json number,title,body,state,labels,comments
```

Stop and say so if the argument is missing, is not a number, or the issue does not
exist. Read existing comments before doing anything else so you do not repeat an
investigation that is already recorded.

## 2. Record the environment

The comment needs these, so collect them first:

```bash
sw_vers -productVersion
xcodebuild -version | head -1
git rev-parse --short HEAD
git status --porcelain
```

## 3. Choose a method

Pick the lightest method that can settle the report, and say in the comment which
one you used and why.

- **On-screen behavior** (menus, windows, titles, dialogs, orientation): build and
  launch the app, observe, and screenshot. See section 4.
- **How the library walk treats files or directories**: first inspect `~/Music`
  directly with `ls`, `mdls -name kMDItemDisplayName`, and `GetFileInfo`, then
  trace the code path in `dmus/MusicLibrary.swift` and `dmus/MusicRootDirectory.swift`.
  Launch the app only if the on-disk evidence and the code do not account for the
  report together.
- **Project configuration or requirements**: read `dmus.xcodeproj/project.pbxproj`,
  `dmus/dmus.entitlements`, and `docs/requirements.md`. Use `-showBuildSettings`
  when a setting's effective value matters.

A build failure is itself a finding. Report it rather than working around it.

## 4. Build and launch recipes

In these recipes `$SCRATCHPAD` is the session scratchpad directory from the system
prompt; set it before running them. There is one scheme, `dmus`, and no test
target. The bundle identifier is `cc.donm.dmus`.

macOS:

```bash
xcodebuild -scheme dmus -configuration Debug -destination 'platform=macOS' build 2>&1 | tail -20
APP="$(xcodebuild -scheme dmus -configuration Debug -destination 'platform=macOS' -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR =/{print $3}')/Dmus.app"
open "$APP"
```

Wait a few seconds for the window, then capture and read the screenshot. Save it in
the scratchpad, not the repo:

```bash
screencapture -x "$SCRATCHPAD/issue-$ARGUMENTS.png"
```

For menus or dialogs, drive them with `osascript` (System Events) before capturing.
Quit when done:

```bash
osascript -e 'quit app "dmus"'
```

iOS Simulator:

```bash
xcrun simctl boot "iPhone 15" 2>/dev/null; open -a Simulator
xcodebuild -scheme dmus -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -20
APP="$(xcodebuild -scheme dmus -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR =/{print $3}')/Dmus.app"
xcrun simctl install booted "$APP"
xcrun simctl launch booted cc.donm.dmus
xcrun simctl io booted screenshot "$SCRATCHPAD/issue-$ARGUMENTS-ios.png"
```

Pick another available device from `xcrun simctl list devices available` if the
issue names a different form factor. Shut the simulator down afterward with
`xcrun simctl shutdown booted`.

## 5. Write and post the comment

Write the comment to a file in the scratchpad, then post it and print the URL that
`gh` returns:

```bash
gh issue comment $ARGUMENTS --body-file "$SCRATCHPAD/issue-$ARGUMENTS-comment.md"
```

Write it as prose with backticked identifiers, in the style of
[comment-example.md](comment-example.md). Cover, in this order:

1. One opening line with the outcome: **Reproduced**, **Confirmed in code**,
   **Could not reproduce**, or **Blocked** with the reason.
2. One environment line: macOS version, Xcode version, commit, and whether the tree
   was clean.
3. The steps actually taken, numbered and specific enough to rerun.
4. What was observed, quoting exact strings, paths, and error text.
5. Where the behavior comes from in the code, as `path:line` references, when you
   identified it.
6. Anything the issue asks about that you could not check.

Do not attach screenshots unless the result cannot be described in words.

## 6. Finish

Tell the user the outcome in one line and give the comment URL. Confirm that
`git status` shows no changes to tracked files.
