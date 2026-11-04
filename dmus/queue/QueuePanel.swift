#if os(iOS)
import Model
import SwiftUI
import Wrappers

struct QueuePanel: View {
    @Environment(Player.self) private var player

    private var queue: Queue { player.queue }

    var body: some View {
        Panel(title: "Queue") {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } accessory: {
            clearButton
        }
    }

    private var clearButton: some View {
        Button("Clear", action: player.clear)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(queue.isEmpty)
    }

    @ViewBuilder
    private var content: some View {
        if queue.isEmpty {
            ContentUnavailableView(
                "No tracks",
                systemImage: "list.bullet",
                description: Text("The queue is empty.")
            )
        } else {
            VStack(spacing: 0) {
                PlayerPanel()
                Divider()
                queueTable
            }
        }
    }

    private var queueTable: some View {
        ScrollViewReader { proxy in
            List(queue.queuedTracks) { queuedTrack in
                QueuedTrackRow(track: queuedTrack.track)
            }
            .listStyle(.plain)
            .onChange(of: queue.queuedTracks.last?.id) { _, lastID in
                if let lastID {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }
}

#Preview("Empty") {
    QueuePanel().environment(Player(audio: AudioReal()))
}

#Preview("Filled") {
    let player = Player(audio: AudioReal())
    player.queue.add(Folder(path: "/Music/Artist", name: "Artist", children: [
        .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
            .track(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3")),
            .track(Track(trackName: "Another Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Another Song.mp3")),
        ])),
        .track(Track(trackName: "Single", albumName: "Artist", artistName: Track.noArtist, path: "/Music/Artist/Single.m4a")),
        .track(Track(
            trackName: "A Track Name Long Enough That It Must Be Elided To Fit The Row",
            albumName: "An Album Name Long Enough That It Must Be Elided To Fit",
            artistName: "An Artist Name Long Enough That It Must Be Elided",
            path: "/Music/Artist/Long.mp3"
        )),
    ]))
    return QueuePanel().environment(player)
}
#endif
