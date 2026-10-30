# Draft requirements

The **player** is a wrapper around the operating system sound libraries and the
state of playback. The player exposes these properties: **current track**, **is
playing** and **time index** and **queue**. An empty player has a nil value for
current track, false for "is playing", 0 for time index and an empty queue. The
current track property is calculated as the first track in the queue, or nil if
the queue is empty.


# Model commands and notifications

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
