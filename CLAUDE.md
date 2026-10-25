# Dmus

An offline music player for macOS and iOS. Requirements are in
`docs/requirements.md`; ignore `docs/draft-requirements.md` unless asked.

## Code style

- Do not write comments that restate what the code already says. A doc comment
  like "The files panel displays the music library" above `struct FilesPanel`
  adds nothing; omit it.
- Comment only to explain what the code cannot: why a decision was made, a
  non-obvious constraint, or a workaround and what it works around.
