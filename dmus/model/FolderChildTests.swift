import Foundation
import Testing

struct FolderChildTests {
    @Test func nestedFolderChildRoundTripsThroughJSON() throws {
        let child = FolderChild.folder(Folder(path: "/Music/Artist", name: "Artist", children: [
            .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
                .track(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3")),
            ])),
            .track(Track(trackName: "Single", albumName: "Artist", artistName: Track.noArtist, path: "/Music/Artist/Single.m4a")),
        ]))

        let data = try JSONEncoder().encode(child)
        let decoded = try JSONDecoder().decode(FolderChild.self, from: data)

        #expect(decoded == child)
    }
}
