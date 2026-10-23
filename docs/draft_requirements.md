# Requirements

This document contains requirements for "dmus" (capitalized "Dmus"), a
cross-platform, offline music player application. Requirements in this document
are written in [EARS][], the "easy approach to requirements syntax".

[EARS]: https://github.com/donmccaughey/ears/blob/main/ears-cheat-sheet.md

This document uses the additional pattern ON for requirements that vary
according to operating system.

    On <operating system>,
    the <system name> shall <system response>.

# Overview

Dmus shall run on macOS and iOS; where "iOS" includes both iPhone and iPad form
factors.

Dmus shall play music files from the local filesystem.

Dmus shall support `.mp3` and `.m4a` music files without DRM.


# Model

The **music directory** is the directory on the local filesystem that dmus
searches for music files.

The **music library** is an in-memory tree data structure consisting of folders
(branch nodes) and tracks (leaf nodes) that correspond to directories and music
files in the music directory, with a root folder for the music directory itself,
one folder for each non-empty directory and one track for each music file. The
music library exposes these properties: **root folder** and **music directory
path**. An empty music library contains only the root folder.

A **track** is a leaf node of the music library that corresponds to a music
file. A track exposes these properties: **track name** is the filename of the
music file with the extension removed; **album name** is the name of the parent
folder or "(no album)" if the track is a child of the root folder; **artist
name** is the name of the grandparent folder or "(no artist)" if the track is a
grandchild of the root folder; **file path** is the absolute path to the music
file.

A **folder** is a branch node of the music library that corresponds to a
directory, including the root folder for the music directory itself. A folder
exposes one property: **name** is the filename of the directory or "(music
library)" for the root folder.

The **queue** is an in-memory data structure consisting of the list of tracks
being played. The queue exposes one property: **tracks** is the list of tracks
in the queue. An empty queue contains an empty tracks list.

The **player** is a wrapper around the operating system sound libraries and the
state of playback. The player exposes these properties: **current track**, **is
playing** and **time index** and **queue**. An empty player has a nil value for
current track, false for "is playing", 0 for time index and an empty queue. The
current track property is calculated as the first track in the queue, or nil if
the queue is empty.


# Model commands and notifications

When given the **reload** command, the music library shall walk the music
directory, creating the corresponding folders and tracks.

When the reload command complete, the music library shall send the **music
library did reload** notification containing the music library.

When given the **add track** command, the queue shall append the given track.

When it adds a track, the queue shall send the **did add track to queue**
notification containing the track and the queue.

When given the **add folder** command, the queue shall append the track
descendants of the folder in preorder.

When it adds a folder, the queue shall send the **did add folder to queue**
notification containing the folder, the list of its track descendants in
preorder and the queue.

When given the **play** command, the player shall begin playback for the current
track.

When it begins playback for the current track, the player shall send the **did
begin playback** notification containing the current track.

When given the **stop** command, the player shall stop playback for the current
track.

When it stops playback for the 

The **did stop playback** notification is sent when playback stops; it contains
no data.

The **rewind** notification is sent to rewind the current track to the start; it
contains no data.

The **skip** notification is sent to skip to the next track; it contains no
data.

The **now playing** notification is sent when a track begins or resumes playing;
it contains the track and the time index.

The **clear queue** notification is sent to stop playing and clear all tracks
from the queue.


# Music storage

Dmus shall have one filesystem directory designated as the music directory.

On macOS, dmus shall use the users `~/Music/` directory as the default music
directory.

On macOS, dmus shall allow the music directory to be changed in settings.

On iOS, dmus shall use the `Music/` subdirectory of the standard application
support directory as the music directory, creating it on launch if it does not
exist.

On iOS, dmus shall exclude the music directory from backup.


# Launch behavior

When the app launches, dmus shall walk the music directory in the background and
build the music library.

When the music library is built, dmus shall send a "reload music library"
notification containing the music library.


# User interface

The **files panel** is a view that displays the music library.

The **queue panel** is a view that displays the queue and player controls.

Dmus shall have a main window or view that shows the files panel and the queue
panel.

On macOS, the files panel shall be on the left side and the queue panel on the
right side of the main window.

On macOS, the files panel and queue panel shall occupy equal amounts of space.

On iOS, while the screen is in portrait orientation, the files panel shall be on
the top and the queue panel on the bottom of the main view.

On iOS, while the screen is in portrait orientation, the files panel and queue
panel shall occupy equal amounts of space.

On iOS, while the screen is in landscape orientation, the files panel shall be
on the left side and the queue panel on the right side of the main view.

On iOS, while the screen is in landscape orientation, the files panel and queue
panel shall occupy equal amounts of space.


## Files panel

The **files tree** is a tree view that displays the music library.

A **folder item** is a subview in the files tree that contains a folder shows
the folder name.

A **track item** is a subview in the files tree that contains a track and shows
the track name.

On macOS, the files panel shall contain the files tree.

On macOS, when the app launches, dmus shall display an empty music library in the
files tree.

On macOS, when a "reload music library" notification is sent, the files tree shall reload itself using the music library in the notification.

On macOS, when a track item is dragged from the files panel and dropped on the
queue panel, dmus shall send an "add track to queue" notification containing
the corresponding track.

On macOS, when a folder item is dragged from the files panel and dropped on the
queue panel, dmus shall send an "add folder to queue" notification containing
the corresponding folder and a list of its track descendants in preorder.

The **files table stack** is a navigation stack that displays the music library.

A **folder table** is a table view that shows one row for each folder or track
child of the corresponding folder, sets the title to the name of the folder and
a "+" button in the title bar.

A **folder row** is a folder table row that shows the name of the corresponding
folder and contains a "+" button on the right side of the row.

A **track row** is a folder table row that shows the track name of the
corresponding track and contains a "+" button on the right side of the row.

On iOS, the files panel contain the files table stack.

On iOS, when the app launches, dmus shall show an empty music library in the
files table stack.

On iOS, while the visible folder table is empty, dmus shall disable the "+"
button in the title bar of the files panel.

On iOS, while the visible folder table is not empty, dmus shall enable the "+"
button in the title bar of the files panel.

On iOS, when the user taps the "+" button in a track row, dmus sends "add track
to queue" notification containing the corresponding track.

On iOS, when the user taps the "+" button in a folder row, dmus sends "add
folder to queue" notification containing the corresponding folder and a list of
its track descendants in preorder.

On iOS, when the user taps the "+" button in a folder table title bar, dmus
sends "add folder to queue" notification containing the corresponding folder and
a list of its track descendants in preorder.

On iOS, when the user taps a folder row, dmus pushes a new folder table onto the
files table stack for the corresponding folder.


## Queue panel

The **player panel** is a view that contains the back button, play/stop button,
next button and clear button.

The **queue table** is a table view that shows one row per track in the queue.

The queue panel shall show the player panel at the top and the queue table in
the remaining space.

When the app launches, dmus shall disable the back button, the play/stop button,
the next button and the clear button and show the play icon in the play/stop
button.

When the app launches, dmus shall display an empty queue in the queue table.

While the queue is empty, dmus shall disable the back button, play/stop button,
next button and clear button.

While the queue contains one or more tracks, dmus shall enable the back button,
play/stop button, next button and clear button and add one row to the queue
table for each track in the queue.

While a track is playing, dmus shall show the play icon on the play/stop button.

While a track is not playing, dmus shall show the stop icon on the play/stop
button.

While a track is not playing, when the user taps or clicks the play button, dmus
shall begin playing the first track in the queue starting at the time index
property, set the "is playing" property to true and enable the back button and
next button.

While a track is not playing, the queue table shall show the first row with
the default row style.

While a track is playing, the queue table shall show the first row with the
track title in bold and a heavy border around the row.

While a track is playing, when the track completes, dmus shall remove the track
from the queue and the corresponding row from the queue table.

While there are more tracks in the queue, when a track completes, dmus shall
begin playing the next track in the queue.

While there are no more tracks in the queue, when a track completes, dmus shall
stop playing, set the queue "is playing" property to false and the time index
property to zero.

While a track is playing, when the user taps or clicks the back button, dmus
shall set the queue time index property to zero and begin playing the track from
the beginning.

Wile a track is playing, when the user taps or clicks the next button, dmus shall stop playing the track


# File sync

Dmus shall act as a file sync server on macOS.

Dmus shall act as a file sync client on iOS and iPadOS.
