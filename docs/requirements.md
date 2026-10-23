# Requirements

This document contains requirements for "dmus" (capitalized "Dmus"), a
cross-platform, offline music player applications. Requirements in this document
are written in [EARS][], the "easy approach to requirements syntax".

[EARS]: https://github.com/donmccaughey/ears/blob/main/ears-cheat-sheet.md

This document uses the additional pattern ON for requirements that vary
according to operating system.

    On <operating system>,
    the <system name> shall <system response>.

# Overview

Dmus shall run on macOS, iOS and iPadOS.

Dmus shall play music files from the local filesystem.

Dmus shall support `.mp3` and `.m4a` files without DRM.


# Music storage

Dmus shall have one filesystem directory designated as the music directory.

On macOS, dmus shall use the users `~/Music/` directory as the default music
directory.

On macOS, dmus shall allow the music directory to be changed in settings.

On macOS, dmus shall use the `Library/Application Support/Music/` directory as
the music directory.

On macOS, dmus shall exclude the `Library/Application Support/Music/` directory
from backup.


# User interface

Dmus shall have a main window or main view that shows two panels: files and
player.

On macOS and iPadOS, the files panel shall be on the left side and the player
panel on the right side of the main window or main view, respectively.

On iOS, the files panel shall be on the bottom and the player panel on the top
of the main view.


## File panel

On macOS, the files panel shall be a tree view showing the music directory all
its descendent files and directories.

On iOS, the files panel contain the music table, a table with a row for each
entry in the music directory.

On iOS, when the user taps on a music table row representing a music file, it
is added to the queue in the player panel.

On iOS, when the user taps on a music table row representing a subdirectory, a
new music table for that subdirectory is pushed onto the navigation stack.


## Player panel

The player panel shall show music player controls at the top of the panel: track
time elapsed, previous track button, play/stop button, next track button, track
time remaining, track title, album title, artist and edit queue button.

The player panel shall show a list of queued tracks below the music player
controls.

The player panel shall show one row per queued track; each row shall display the
track title, album title, artist and track time.


# File sync

Dmus shall act as a file sync server on macOS.

Dmus shall act as a file sync client on iOS and iPadOS.
