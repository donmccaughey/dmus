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

Dmus shall use the default version of Swift supported by Xcode 26 that runs on
the target macOS and iOS operating systems.

Dmus shall use the default version of the SwiftUI framework supported by Xcode
26 that runs on the target macOS and iOS operating systems.

On macOS, dmus shall use AppKit rather than Mac Catalyst.


# User interface

On macOS, dmus shall show a main window on launch.

On iOS, dmus shall show a main view on launch.

On macOS, dmus shall show two equally-sized panels in the main window: the files
panel on the left side and the queue panel on the right side.

On iOS, while the screen is in portrait orientation, dmus shall show two
equally-sized panels in the main view: the files panel shall be on the top and
the queue panel on the bottom.

On iOS, while the screen is in landscape orientation, dmus shall show two
equally-sized panels in the main view: the files panel shall be on the left side
and the queue panel on the right side.
