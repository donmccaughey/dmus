import Foundation
import Model
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
        #expect(queue.queuedTracks[0].identifier != queue.queuedTracks[1].identifier)
    }

    @Test func addingFolderAppendsTrackDescendantsInPreorder() {
        let folder = Folder(path: "/Music/Artist", name: "Artist", children: [
            Folder(path: "/Music/Artist/Album", name: "Album", children: [song]),
            single,
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
        let album = Folder(path: "/Music/Artist/Album", name: "Album", children: [song])
        let queue = Queue()
        queue.add([single, album])
        #expect(queue.tracks == [single, song])
    }
}

extension QueueTests {
    @Test func removingFirstDropsTheHeadOfTheQueue() {
        let queue = Queue()
        queue.add(song)
        queue.add(single)
        queue.removeFirst()
        #expect(queue.tracks == [single])
    }

    @Test func removingFirstFromEmptyQueueChangesNothing() {
        let queue = Queue()
        queue.removeFirst()
        #expect(queue.isEmpty)
    }

    @Test func clearingRemovesAllTracks() {
        let queue = Queue()
        queue.add(song)
        queue.add(single)
        queue.clear()
        #expect(queue.isEmpty)
    }

    @Test func mutationsPostDidChange() {
        let queue = Queue()
        let changes = NotificationCounter(name: Queue.didChangeNotification, object: queue)
        queue.add(song)
        queue.add(Folder(path: "/Music/Artist", name: "Artist", children: [single]))
        queue.removeFirst()
        queue.clear()
        #expect(changes.count == 4)
    }

    @Test func addingChildrenPostsOnce() {
        let album = Folder(path: "/Music/Artist/Album", name: "Album", children: [song])
        let queue = Queue()
        let changes = NotificationCounter(name: Queue.didChangeNotification, object: queue)
        queue.add([single, album])
        #expect(queue.tracks == [single, song])
        #expect(changes.count == 1)
    }

    @Test func addingNothingPostsNothing() {
        let queue = Queue()
        let changes = NotificationCounter(name: Queue.didChangeNotification, object: queue)
        queue.add(Folder())
        queue.removeFirst()
        queue.clear()
        #expect(changes.count == 0)
    }
}
