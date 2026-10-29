import Foundation
import Testing

struct FolderTests {
    @Test func emptyFolderHasNoTrackDescendants() {
        #expect(Folder().trackDescendants.isEmpty)
    }

    @Test func directTracksAreDescendantsInOrder() {
        let first = track("A")
        let second = track("B")
        let folder = Folder(path: "/Music", name: "Music", children: [.track(first), .track(second)])

        #expect(folder.trackDescendants == [first, second])
    }

    @Test func nestedTracksAreDescendantsInPreorder() {
        let loose = track("Loose")
        let albumOne = track("Album One Song")
        let albumTwo = track("Album Two Song")
        let single = track("Single")
        let folder = Folder(path: "/Music", name: "Music", children: [
            .folder(Folder(path: "/Music/Artist", name: "Artist", children: [
                .folder(Folder(path: "/Music/Artist/One", name: "One", children: [.track(albumOne)])),
                .track(single),
                .folder(Folder(path: "/Music/Artist/Two", name: "Two", children: [.track(albumTwo)])),
            ])),
            .track(loose),
        ])

        #expect(folder.trackDescendants == [albumOne, single, albumTwo, loose])
    }

    private func track(_ name: String) -> Track {
        Track(trackName: name, albumName: Track.noAlbum, artistName: Track.noArtist, path: "/Music/\(name).mp3")
    }
}
