# Dmus

An offline music player for macOS and iOS. Requirements are in
`docs/requirements.md`; ignore `docs/draft-requirements.md` unless asked.

## Code style

Do not write comments that restate what the code already says. A doc comment
like "The files panel displays the music library" above `struct FilesPanel` adds
nothing; omit it.

Comment only to explain what the code cannot: why a decision was made, a
non-obvious constraint, or a workaround and what it works around.

Extract variables and functions to make code more expressive at the call sight,
reducing the need for comments. For example, before:

    var body: some Scene {
        // defaultSize measures the whole window frame while the frame modifier
        // above measures the content area below the title bar, so add the
        // title bar height to keep both in content area terms.
        .defaultSize(width: 900, height: 600 + Self.titleBarHeight)
    }

After extracting the `defaultContentAreaSize()` method:

    var body: some Scene {
        .defaultContentAreaSize(width: 900, height: 600)
    }

    extension Scene {
        func defaultContentAreaSize(width: CGFloat, height: CGFloat) -> some Scene {
            // defaultSize() sets the overall window size
            // so add the title bar height to the given content area height
            defaultSize(width: width, height: height + titleBarHeight)
        }
    }
