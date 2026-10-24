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

On macOS, dmus shall not use the App Sandbox, since dmus is not distributed
through the App Store.

Dmus shall use only APIs available on the minimum deployment targets.

On iOS, dmus shall declare support for all four interface orientations:
portrait, portrait upside-down, landscape left and landscape right.


# Model

The **music directory** is the directory on the local filesystem that dmus
searches for music files.

On macOS, dmus shall use the current user's default music directory as the music
directory, creating it on launch if it does not exist.

On iOS, dmus shall use the `Music/` subdirectory of the standard application
support directory as the music directory, creating it on launch if it does not
exist.

On iOS, dmus shall exclude the music directory from backup.

A **music file** is a regular file with an `.mp3` or `.m4a` extension (case
insensitive) that is not hidden.


## Music library

A **music library** is an in-memory tree data structure consisting of folders
(branch nodes) and tracks (leaf nodes) that correspond to directories and music
files in the music directory, with a root folder for the music directory itself,
one folder for each directory and one track for each music file. A music library
has one property: **root folder**.

An **empty music library** is a music library where the root folder is an empty
folder.

A music library shall have a no argument initializer that creates an empty music
library.

A music library shall have a one argument initializer that takes a folder to set
as the root folder.

A music library shall have an **is empty** read-only calculated property that is
true when the root folder has no children and false otherwise.

A music library shall have a static **load** method that is called with a given
music directory. The load method shall create a root folder with folders and
tracks created by walking the given music directory and return a new music
library initialized with the root folder.

If the load method encounters an error, the music library shall send a **music
library load did fail** notification.

When the load method completes, the music library shall send a **music
library did load** notification containing the new music library on the main
thread.


## Folder

A **folder** is a branch node of the music library that corresponds to a
directory. A folder has these properties: **path** is the absolute path of the
corresponding directory or `nil` for an empty folder; **name** is the filename
of the directory or "Music Library" for the root folder; **children** is the
list of folders and tracks that belong to the folder.

An **empty folder** is a folder with a path value of `nil`, a name value of
"Music Library" and an empty children list.


## Track

A **track** is a leaf node of the music library that corresponds to a music
file. A track exposes these properties: **track name** is the filename of the
music file with the extension removed; **album name** is the name of the parent
folder or "(no album)" if the track is a child of the root folder; **artist
name** is the name of the grandparent folder or "(no artist)" if the track is a
child or grandchild of the root folder; **path** is the absolute path to the
music file.


# Launch behavior

When the app launches, dmus shall create an empty music library owned by the app
and shared with other views.

When the app launches, dmus shall listen for "music library did load"
notifications.

When it receives a "music library did load" notification, the app shall replace
the app music library with the one in the notification when received.

When the app launches, dmus shall call the music library load method in the
background, passing it the music directory.


# User interface

On macOS, dmus shall show a main window on launch.

On iOS, dmus shall show a main view on launch.

On macOS, dmus shall show two equally-sized panels in the main window: the files
panel on the left side and the queue panel on the right side.

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


## Files panel

The files panel shall show the title "Files" at the top of the panel.

When it loads, the files panel shall listen for the "music library did load"
notifications.

When it loads, the files panel shall listen for the "music library load did
fail" notification.

When it loads, the files panel shall get its music library from the app.

While its music library is empty, the files panel shall show a content
unavailable view with title "No music", description "The music library is
empty." and a folder system icon.

While its music library is not empty, the files panel shall hide the content
unavailable view.

When it receives the "music library did load" notification, the files panel
shall replace its music library with the music library from the notification.

When it receives the "music library load did fail" notification, the files panel
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

On macOS, while its music library is not empty, the files panel shall show a
files tree backed by its music library.


### Files table stack

The **files table stack** is a navigation stack that displays the music library
on iOS.

A **folder table** is a table view that shows one row for each folder or track
child of the corresponding folder, sets the title to the name of the folder and
adds a "+" button in the navigation bar.

A **folder row** is a folder table row that shows the name of the corresponding
folder and contains a "+" button on the right side of the row.

A **track row** is a folder table row that shows the track name of the
corresponding track and contains a "+" button on the right side of the row.

On iOS, while its music library is empty, the files panel shall hide the files
table stack.

On iOS, while its music library is not empty, the files panel shall show a files
table stack backed by its music library.

On iOS, while the visible folder table is empty, the folder table shall disable
the "+" button in the navigation bar.

On iOS, while the visible folder table is not empty, the folder table shall
enable the "+" button in the navigation bar.

On iOS, when the user taps a folder row, the files table stack shall push a new
folder table onto the navigation stack backed by the folder of the tapped row.


## Queue panel

The queue panel shall show the title "Queue" at the top of the panel.

The queue panel shall show a content unavailable view with title "No tracks",
description "The queue is empty." and a bullet list system icon.
