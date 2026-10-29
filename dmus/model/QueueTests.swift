import Foundation
import Testing

struct QueueTests {
    let song = Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3")
    let single = Track(trackName: "Single", albumName: "Artist", artistName: Track.noArtist, path: "/Music/Artist/Single.m4a")

    @Test func startsEmpty() {
        let queue = Queue()
        #expect(queue.isEmpty)
        #expect(queue.tracks.isEmpty)
    }

    @Test func addingTrackAppendsIt() {
        let queue = Queue()
        queue.add(single)
        queue.add(song)
        #expect(!queue.isEmpty)
        #expect(queue.tracks == [single, song])
    }

    @Test func addingSameTrackTwiceQueuesTwoDistinctEntries() {
        let queue = Queue()
        queue.add(song)
        queue.add(song)
        #expect(queue.tracks == [song, song])
        #expect(queue.queuedTracks[0].id != queue.queuedTracks[1].id)
    }

    @Test func addingFolderAppendsTrackDescendantsInPreorder() {
        let folder = Folder(path: "/Music/Artist", name: "Artist", children: [
            .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [.track(song)])),
            .track(single),
        ])
        let queue = Queue()
        queue.add(folder)
        #expect(queue.tracks == [song, single])
    }

    @Test func addingEmptyFolderChangesNothing() {
        let queue = Queue()
        queue.add(song)
        queue.add(Folder())
        #expect(queue.tracks == [song])
    }

    @Test func addingChildrenDispatchesOnKind() {
        let album = Folder(path: "/Music/Artist/Album", name: "Album", children: [.track(song)])
        let queue = Queue()
        queue.add([.track(single), .folder(album)])
        #expect(queue.tracks == [single, song])
    }
}
