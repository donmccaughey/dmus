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
factors and both iOS and iPadOS operating systems.


# Project configuration

Dmus shall use Xcode 26 and be built on macOS 15 Sequoia.

On macOS, dmus shall target macOS 15 Sequoia or later.

On iOS, dmus shall target iOS 18 (including iPadOS 18) or later.

Dmus shall use Swift language and the SwiftUI framework.

On macOS, dmus shall use AppKit rather than Mac Catalyst.

On macOS, dmus shall **not** use the App Sandbox, since dmus is not distributed
through the App Store.

Dmus shall use only APIs available on the minimum deployment targets.

On iOS, dmus shall declare support for all four interface orientations:
portrait, portrait upside-down, landscape left and landscape right.


# General definitions

A **localized display name** is the name of a directory or file obtained from
macOS or iOS API calls like `FileManager.displayName(atPath:)`, which may differ
from the actual filesystem name of the directory or file. See the [Localized
Display Name](localized-display-name-2026-10.md) document for details.


# Project organization

The dmus project shall place app code, configuration and assets in the `dmus/`
subdirectory.

The dmus project shall place documentation files in the `docs/` subdirectory.


## Code organization

The dmus project shall place model code in the `dmus/model/` subdirectory.

The dmus project shall place user interface (UI) code in the `dmus/ui/`
subdirectory.

The dmus project shall place all other code, app configuration and app asset
files in the `dmus/` subdirectory.

The dmus project shall place each class or struct representing a significant
application concept in its own code file; extensions and small classes and
structs may share a code file when they have a single consumer.

The dmus project shall create [wrapper interfaces](wrappers-for-testing.md) for
system services that are difficult to test in isolation, such as the file
system, network, audio playback, clock and random number generator.

The dmus project shall place wrapper interfaces and their real and fake
implementations in the `dmus/wrappers/` subdirectory.

The dmus project shall place unit test files in the same folder as the code file
under test.


# System service wrappers

The **file system wrapper** shall wrap general file system information and
operations.

The **preferences wrapper** shall wrap user defaults and other settings.


## Audio wrapper

The **audio library** is collectively the set of system audio APIs used to
implement playback.

The audio library shall support gapless playback of `.mp3` and `.m4a` files.

The **audio wrapper** shall wrap the audio library, exposing high level
operations in the application domain.


# Model

The **music root directory** is the directory on the local filesystem that dmus
searches for music files.

On macOS, dmus shall read the music root directory from user defaults,
initializing it to the system music directory for the current user if not
present.

On macOS, dmus shall create the music root directory on launch if it does not
exist.

On iOS, dmus shall use the `Music/` subdirectory of the standard application
support directory as the music root directory, creating it on launch if it does
not exist.

On iOS, dmus shall exclude the music root directory from backup.

A **music directory** is a directory under the music root directory that is not
hidden and is not a package.

A **music file** is a regular file with an `.mp3` or `.m4a` extension (case
insensitive) that is not hidden.


## Music library

A **music library** is an in-memory tree data structure consisting of folders
(branch nodes) and tracks (leaf nodes) that correspond to music directories and
music files in the music root directory, with a root folder for the music root
directory itself, one folder for each music directory and one track for each
music file. A music library has one property: **root folder**.

An **empty music library** is a music library where the root folder is an empty
folder.

A music library shall have a no argument initializer that creates an empty music
library.

A music library shall have a one argument initializer that takes a folder to set
as the root folder.

A music library shall have an **is empty** read-only calculated property that is
true when the root folder has no children and false otherwise.

A **load result** is the value returned by a load function. A load result has
these properties: **library** is the music library that was loaded; **errors**
is the list of errors encountered while loading, which is empty when loading
succeeded completely.

Dmus shall have a **load music library** function that is called with the path
of the music root directory. The load music library function shall create a root
folder with folders and tracks created by walking the given music root directory
and return a load result containing a new music library initialized with the
root folder.

If it cannot list the music root directory, the load music library function
shall return a load result containing an empty music library and the error.

If it encounters an error while walking a subdirectory or file, the load music
library function shall add the error to the load result and continue walking.

Dmus shall have a **load demo music library** function that is called without
arguments. The load demo music library function shall read the `demo-data.json`
file from the app bundle then create a root folder with folders and tracks
created by walking the first JSON object in the file with member
`"type"="directory"`.

The load demo music library function shall set the path property of each track
to the path of the `demo-track.mp3` file from the app bundle instead of
calculating the path from `demo-data.json`.

The load demo music library function shall use all applicable rules on the file
and directory names when creating folders and tracks, ignoring rules that only
apply to real directories and files.

The load demo music library function shall discard directories that end with the
`.itlp` extension, as these directories are packages.

If it encounters an error, the load demo music library function shall return a
load result containing an empty music library and the error.

When it completes, the load demo music library function shall return a load
result containing the new music library and no errors.


## Folder

A **folder** is a branch node of the music library that corresponds to a
directory. A folder has these properties: **path** is the absolute path of the
corresponding directory or `nil` for an empty folder; **name** is the localized
display name of the directory or "Files" for the root folder; **children** is
the list of folders and tracks that belong to the folder.

An **empty folder** is a folder with a path value of `nil`, a name value of
"Files" and an empty children list.


## Track

A **track** is a leaf node of the music library that corresponds to a music
file. A track exposes these properties: **track name** is the localized display
name of the music file with the extension removed; **album name** is the
localized display name of the parent folder or "(no album)" if the track is a
child of the root folder; **artist name** is the localized display name of the
grandparent folder or "(no artist)" if the track is a child or grandchild of the
root folder; **path** is the absolute path to the music file.


## Queue

The **queue** is an in-memory list of tracks to play. The queue has one
property: **tracks** is the list of tracks in the queue, in play order. The same
track may appear in the queue more than once. The queue is owned by the player.

The queue is an **empty queue** when the tracks list is empty.

When given the **add track** command, the queue shall append the given track to
its tracks.

When given the **add folder** command, the queue shall append the track
descendants of the given folder to its tracks in preorder.

When given the **clear** command, the queue shall remove all tracks from its
tracks.


## Player

The **player** is the coordinator of track playback. The player owns the queue.

A **time index** is a non-negative number of seconds, including fractional
seconds, measured from the start of the current track. A time index beyond the
end of the current track is invalid and is clamped to the end of the track.

The player shall have an **audio** property that is the audio wrapper.

The player shall have a **queue** property that is its queue.

The player shall have a **current track** read-only calculated property that
returns the first track in the queue, or `nil` when the queue is empty.

The player shall have a **next track** read-only calculated property that
returns the second track in the queue, or `nil` when the queue contains fewer
than two tracks; the next track is passed to the audio wrapper to support
gapless playback.

The player shall have a **time index** property that is the time index for the
current track, or zero when the current track is `nil`.

The player shall have an **is playing** read-only boolean property that returns
true when the player is in the playback state and false when in the stopped
state. The "is playing" property may be implemented as a variable or as a
calculated property read from the audio wrapper.

**Playback** is the player state where audio is being played.

**Stopped** is the player state where no audio is being played. The player does
not have a separate "paused" state: the current track and time index properties
control where playback starts or resumes.


## Playback

While in playback and while there is a next track, when it finishes playing the
current track, the audio wrapper shall begin playing the next track without a
gap.

While in playback and while there is no next track, when it finishes playing the
current track, the audio wrapper shall stop playback.

While in playback, when the audio wrapper finishes playing the current track,
the player shall remove it from the queue.

While in playback, the player shall keep the time index in sync with the audio
wrapper by callback, notification or polling.


## Play command

While in playback, if given the **play** command, the player shall ignore the
command.

While stopped and while there is a current track, when given the play command,
the player shall start playing the current track at the time index and enter the
playback state.


## Stop command

While stopped, if given the **stop** command, the player shall ignore the
command.

While in playback, when given the stop command, the player shall update the time
index to the current playback position, stop audio playback and enter the
stopped state.


## Back command

While the queue is not empty, when given the back command, the player shall set
the time index to zero.

While in playback, when given the back command, the player shall begin playing
the current track from the start.


## Next command

While the queue is not empty, when given the next command, the player shall set
the time index to zero and discard the current track.

While in playback and while there is a next track, when given the next command,
the player shall stop playing the current track and begin playing the next track
from the start.

While in playback and while there is no next track, when given the next command,
the player shall stop playing the current track and enter the stopped state.


## Clear command

While the queue is not empty, when given the clear command, the player shall set
the time index to zero and clear the queue.

While in playback, when given the clear command, the player shall stop playback
and enter the stopped state.


## Command availability

While the queue is empty, the player shall ignore the play, stop, back, next and
clear commands.


# Launch behavior

The **music library store** is the object owned by the app that holds the app
music library and the errors from the most recent load. The music library store
has these properties: **library** is the app music library, initially an empty
music library; **load errors** is the list of errors from the most recent load,
initially empty; **load did fail** is a read-only calculated property that is
true when load errors is not empty.

When the app launches, dmus shall create a music library store and share it with
other views.

When the app launches, dmus shall create a player with an empty queue and share
the player with other views.

When the app launches and the `--demo` command line option is **not** given,
dmus shall call the load music library function in the background, passing it
the path of the music root directory.

When the app launches and the `--demo` command line option is given, dmus shall
call the load demo music library function in the background.

If locating the music root directory or reading the demo files from the app
bundle fails, dmus shall treat the failure as a load result containing an empty
music library and the error.

When a background load completes, dmus shall apply its load result to the music
library store on the main thread, replacing the library and the load errors.


# User interface

Dmus shall use "Dmus" (not "dmus") wherever the app name name is displayed:
window title, app icon, menus, etc.

On macOS, dmus shall show a main window on launch.

The **main window content area** is the part of the main window below the title
bar; it excludes the title bar and any window border. Main window widths and
heights in this document are content area dimensions.

On macOS, dmus shall give the main window content area a width of 900 and a
height of 600 the first time the app launches.

On macOS, dmus shall give the main window content area a minimum width of 640
and a minimum height of 480.

On macOS, dmus shall retain the previous main window width and height between
subsequent launches.

On macOS, dmus shall show two equally-sized panels in the main window: the files
panel on the left side and the queue panel on the right side.

On macOS, dmus shall only allow one main window without tabs, and shall quit the
app when the main window is closed.

On iOS, dmus shall show a main view on launch.

On iOS, while the screen is in right-side-up portrait orientation, dmus shall
show two equally-sized panels in the main view: the files panel shall be on the
top and the queue panel on the bottom.

On iOS, where the device supports upside-down portrait orientation, while the
screen is in upside-down portrait orientation, dmus shall show two equally-sized
panels in the main view: the files panel shall be on the top and the queue panel
on the bottom.

On iOS, while the screen is in landscape orientation, dmus shall show two
equally-sized panels in the main view: the files panel shall be on the left side
and the queue panel on the right side.

A **panel title** is the title text shown at the top of a panel.

On iOS, dmus shall draw panel titles on an opaque secondary system background.


## Files panel

On macOS, the files panel shall show the title "Files" at the top of the panel.

On iOS, while its music library is empty, the files panel shall show the title
"Files" at the top of the panel.

On iOS, while its music library is **not** empty, the files panel shall hide the
title "Files" at the top of the panel.

The files panel shall get its music library and load did fail state from the
app's music library store.

While its music library is empty, the files panel shall show a content
unavailable view with title "No music", description "The music library is
empty." and a folder system icon.

While its music library is **not** empty, the files panel shall hide the content
unavailable view.

While its music library is empty and load did fail is true, the files panel
shall set the description of the content unavailable view to "The music library
did not load.".


### Files tree

The **files tree** is a tree view that displays a music library on macOS.

A **folder item** is an item in the files tree that contains a folder and shows
the folder name. A folder item can be expanded to show its children or collapsed
to hide them.

A **track item** is an item in the files tree that contains a track and shows
the track name.

On macOS, while its music library is empty, the files panel shall hide the files
tree.

On macOS, while its music library is **not** empty, the files panel shall show a
files tree backed by its music library.

On macOS, when the user drags a folder item, the files tree shall start a drag
carrying the folder of the item.

On macOS, when the user drags a track item, the files tree shall start a drag
carrying the track of the item.


### Files table stack

The **files table stack** is a navigation stack that displays the music library
on iOS.

A **folder table** is a table view that shows one row for each folder or track
child of the corresponding folder, sets the title to the name of the folder and
adds a search button showing the standard search icon in the navigation bar.

A folder table shall draw itself in the standard "plain" style.

A **folder row** is a folder table row that shows the name of the corresponding
folder and contains a "[+]" button (SF Symbol `plus.square`) and a ">" button
(standard disclosure chevron) on the right side of the row.

When the user taps the "[+]" button on a folder row, dmus shall add that folder
to the queue.

When the user taps the ">" button  on a folder row, dmus shall push .

A **track row** is a folder table row that shows the track name of the
corresponding track and contains a "(+)" (SF Symbol `plus.circle`) button on the
right side of the row.

On iOS, when the user taps the "(+)" button on a track row, dmus shall add that
track to the queue.

On iOS, while its music library is empty, the files panel shall hide the files
table stack.

On iOS, while its music library is **not** empty, the files panel shall show a
files table stack backed by its music library.

On iOS, while the visible folder table is empty, the folder table shall disable
the search button in the navigation bar.

On iOS, while the visible folder table is **not** empty, the folder table shall
enable the search button in the navigation bar.

On iOS, the folder table shall draw the navigation bar with the same opaque
background as a panel title, regardless of the folder table's scroll position.

On iOS, when the user taps a folder row, the files table stack shall push a new
folder table onto the navigation stack backed by the folder of the tapped row.


## Queue panel

The queue panel shall show the title "Queue" at the top of the panel.

The queue panel shall get its tracks from the player's queue.

While the queue is empty, the queue panel shall show a content unavailable view
with title "No tracks", description "The queue is empty." and a bullet list
system icon.

While the queue is **not** empty, the queue panel shall hide the content
unavailable view and show the player panel and the queue table.

On macOS, when a track item from the files tree is dropped on the queue panel,
the queue panel shall give the queue the add track command with the track of the
item.

On macOS, when a folder item from the files tree is dropped on the queue panel,
the queue panel shall give the queue the add folder command with the folder of
the item.


### Player panel

The **player panel** is a view containing playback controls: back, play/stop,
next and clear buttons.

The **play/stop button** is a button that shows a play triangle (SF Symbol
`play.fill`) while the player is stopped and shows a stop square (SF Symbol
`stop.fill`) while the player is in playback.

The **back button** is a button that shows the backward double triangle (SF
Symbol `backward.fill`).

The **next button** is a button that shows the forward double triangle (SF
Symbol `forward.fill`).

The **clear button** is a button with the label "clear".

The player panel shall show the play/stop button in the center of the panel, with
the back button aligned to the left side of the play/stop button, the next
button aligned to the right side of the play/stop button and the clear button
aligned to the right side of the panel. The ASCII schematic below shows the
arrangement of buttons in the view.

    +--------------------------------------------------+
    |             [ << ]  [  >  ]  [ >> ]      [clear] |
    +--------------------------------------------------+

The back button, next button and clear buttons shall have the same width.

The play/stop button shall be 20% wider than the back button, next button and
clear button.

The player panel shall have a fixed height tall enough to show its contents with
standard padding and a width that fills the width of the queue panel.

When the queue is empty, the player panel shall disable the back button,
play/stop button, next button and clear button.

When the queue is not empty, the player panel shall enable the back button,
play/stop button, next button and clear button.

While the player is in playback, when the user clicks or taps it, the play/stop
button shall send the stop command to the player.

While the player is stopped, when the user clicks or taps it, the play/stop
button shall send the play command to the player.

When the user clicks or taps it, the back button shall send the back command to
the player.

When the user clicks or taps it, the next button shall send the next command to
the player.

When the user clicks or taps it, the clear button shall send the clear command
to the player.


### Queue table

The **queue table** is a table view with one queued track row for each track in
the queue, in queue order.

A **queued track row** is a table view row in the queue table.

The queue table shall fill all available space in the queue panel below the
player panel.

The queue table shall show a queued track row for each track in the queue, in
the same order as the queue.

The queue table shall draw itself in the standard "plain" style.

When new tracks are added to the queue, dmus shall scroll the queue table to
the end so that the last of the newly added queued track rows are visible.


#### Queued track row

A queued track row shall show the track name, album name and artist name in the
same table cell.

A queued track row shall contain two text lines: upper and lower.

The upper text line of a queued track row shall show the track name.

The lower text line of a queued track row shall show the album name and artist
name in smaller, dimmer text, with the album name on the left and left-justified
and the artist name on the right and right-justified.

The ASCII schematic below shows the arrangement of text in the queued track row.

    +--------------------------------------------------+
    | <track name .................................. > |
    | <album name .............. > < .... artist name> |
    +--------------------------------------------------+
    ^                             ^                    ^
    +------------- 60% -----------+-------- 40% -------+

While the album name and artist name both fit on the lower text line of a queued
track row, each shall occupy the width it needs.

While the album name and artist name do not both fit on the lower text line,
the album name shall occupy up to 60% of the lower text line, inclusive of
padding, and the artist name shall occupy up to 40%.

While the track name, album name or artist name does not fit in the available
space, the queued track row shall use elision to truncate the text.


## Menus

### Settings menu

On macOS, dmus shall have a "Settings…" menu item under the app ("Dmus") menu.

On macOS, when the "Settings…" menu item is selected, dmus shall present the
setting dialog.


## Settings dialog

The settings dialog shall display one setting: **Music files**.

The music files setting shall consist of the **music files text box**, the label
"Music Files:", a read-only text box that displays the current value of the
music root directory, and the **choose music files button**, a button with label
"Choose…".

The music files text box shall **not** accept keyboard focus; the tab order of
the settings dialog shall skip it.

The music files text box shall allow the user to select and copy its text but
shall **not** allow the user to edit it.

When a user clicks the choose music files button, the settings dialog shall open
the system file chooser, initialized to the current path in the music files text
box, and configured to allow the user to choose a directory and with allowed
content types set to `.mp3` and `.m4a` files so that other file types are
dimmed.

When the user chooses a directory in the file chooser, the settings dialog shall
update the music files text box.

When the user chooses a different music root directory in the settings dialog,
dmus shall save the new music root directory to user defaults, load the new
music library in the background and update the app when the new music library
has loaded.
