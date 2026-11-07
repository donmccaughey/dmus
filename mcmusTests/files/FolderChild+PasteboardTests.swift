#if os(macOS)
import AppKit
import Testing

struct FolderChildPasteboardTests {
    let folder = Folder(path: "/Music/Artist", name: "Artist", children: [
        Folder(path: "/Music/Artist/Album", name: "Album", children: [
            Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3"),
        ]),
        Track(trackName: "Single", albumName: "Artist", artistName: Track.noArtist, path: "/Music/Artist/Single.m4a"),
        Folder(path: "/Music/Artist/Empty", name: "Empty", children: []),
    ])
    let track = Track(trackName: "Loose", albumName: Track.noAlbum, artistName: Track.noArtist, path: "/Music/Loose.m4a")

    @Test func nestedFolderRoundTripsThroughPasteboardItem() {
        let item = FolderChildPasteboard.pasteboardItem(for: folder)

        #expect(FolderChildPasteboard.child(in: item) as? Folder == folder)
    }

    @Test func trackRoundTripsThroughPasteboardItem() {
        let item = FolderChildPasteboard.pasteboardItem(for: track)

        #expect(FolderChildPasteboard.child(in: item) as? Track == track)
    }

    @Test func itemWithoutFolderChildDataYieldsNil() {
        let item = NSPasteboardItem()
        item.setString("Song", forType: .string)

        #expect(FolderChildPasteboard.child(in: item) == nil)
    }

    @Test func readsEveryItemOnPasteboardInOrder() {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        pasteboard.clearContents()
        pasteboard.writeObjects([
            FolderChildPasteboard.pasteboardItem(for: folder),
            FolderChildPasteboard.pasteboardItem(for: track),
        ])

        #expect(childrenEqual(FolderChildPasteboard.children(in: pasteboard), [folder, track]))
    }
}
#endif
