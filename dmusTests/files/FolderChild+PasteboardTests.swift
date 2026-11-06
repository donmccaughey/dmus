#if os(macOS)
import AppKit
import Model
import Testing

struct FolderChildPasteboardTests {
    let folder = FolderChild.folder(Folder(path: "/Music/Artist", name: "Artist", children: [
        .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
            .track(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3")),
        ])),
        .folder(Folder(path: "/Music/Artist/Empty", name: "Empty", children: [])),
    ]))
    let track = FolderChild.track(Track(trackName: "Loose", albumName: Track.noAlbum, artistName: Track.noArtist, path: "/Music/Loose.m4a"))

    @Test func folderRoundTripsThroughPasteboardItem() {
        #expect(FolderChild(pasteboardItem: folder.pasteboardItem()) == folder)
    }

    @Test func trackRoundTripsThroughPasteboardItem() {
        #expect(FolderChild(pasteboardItem: track.pasteboardItem()) == track)
    }

    @Test func itemWithoutFolderChildDataYieldsNil() {
        let item = NSPasteboardItem()
        item.setString("Song", forType: .string)

        #expect(FolderChild(pasteboardItem: item) == nil)
    }

    @Test func readsEveryItemOnPasteboardInOrder() {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        pasteboard.clearContents()
        pasteboard.writeObjects([folder.pasteboardItem(), track.pasteboardItem()])

        #expect(FolderChild.folderChildren(in: pasteboard) == [folder, track])
    }
}
#endif
