import SwiftUI

struct QueuePanel: View {
    @Environment(Queue.self) private var queue

    var body: some View {
        Panel(title: "Queue") {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dropDestination(for: FolderChild.self) { children, _ in
                    queue.add(children)
                    return true
                }
        }
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
            Table(queue.queuedTracks) {
                TableColumn("Track", value: \.track.trackName)
                TableColumn("Album", value: \.track.albumName)
                TableColumn("Artist", value: \.track.artistName)
            }
        }
    }
}

#Preview("Empty") {
    QueuePanel().environment(Queue())
}

#Preview("Filled") {
    let queue = Queue()
    queue.add(Folder(path: "/Music/Artist", name: "Artist", children: [
        .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
            .track(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3")),
            .track(Track(trackName: "Another Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Another Song.mp3")),
        ])),
        .track(Track(trackName: "Single", albumName: "Artist", artistName: Track.noArtist, path: "/Music/Artist/Single.m4a")),
    ]))
    return QueuePanel().environment(queue)
}
