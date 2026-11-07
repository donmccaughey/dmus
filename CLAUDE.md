# MC Mus

An offline music player for macOS and iOS. Requirements are in
`docs/requirements.md`. Ignore documents in `docs/drafts/` unless instructed
specifically to consult them.

## Code style

Do not write comments that restate what the code already says. A doc comment
like "The files panel displays the music library" above `struct FilesPanel` adds
nothing; omit it.

Comment only to explain what the code cannot: why a decision was made, a
non-obvious constraint, or a workaround and what it works around.

Extract variables and functions to make code more expressive at the call sight,
reducing the need for comments. For example, before:

    - (void)loadView {
        // ...
        // The window takes its minimum size from its content view's constraints
        // and ignores contentMinSize once it has a content view controller.
        [NSLayoutConstraint activateConstraints:@[
            [view.widthAnchor constraintGreaterThanOrEqualToConstant:640],
            [view.heightAnchor constraintGreaterThanOrEqualToConstant:480],
        ]];
    }

After extracting the `constrainMinimumSize` method:

    - (void)loadView {
        // ...
        [self constrainMinimumSize];
    }

    // The window takes its minimum size from its content view's constraints
    // and ignores contentMinSize once it has a content view controller.
    - (void)constrainMinimumSize {
        [NSLayoutConstraint activateConstraints:@[
            [self.view.widthAnchor constraintGreaterThanOrEqualToConstant:640],
            [self.view.heightAnchor constraintGreaterThanOrEqualToConstant:480],
        ]];
    }
