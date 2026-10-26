import Foundation
import Testing

struct MusicLibraryStoreTests {
    struct SomeError: Error {}

    let library = MusicLibrary(rootFolder: Folder(path: "/Music", name: Folder.rootName, children: [
        .track(Track(trackName: "Song", albumName: Track.noAlbum, artistName: Track.noArtist, path: "/Music/Song.mp3")),
    ]))

    @Test func newStoreIsEmptyAndHasNotFailed() {
        let store = MusicLibraryStore()

        #expect(store.library.isEmpty)
        #expect(!store.loadDidFail)
    }

    @Test func applyingSuccessfulResultSetsLibrary() {
        let store = MusicLibraryStore()

        store.apply(LoadResult(library: library, errors: []))

        #expect(store.library.rootFolder == library.rootFolder)
        #expect(!store.loadDidFail)
    }

    @Test func applyingFailedResultReportsFailure() {
        let store = MusicLibraryStore()

        store.apply(LoadResult(library: MusicLibrary(), errors: [SomeError()]))

        #expect(store.library.isEmpty)
        #expect(store.loadDidFail)
    }

    @Test func applyingSuccessfulResultClearsEarlierFailure() {
        let store = MusicLibraryStore()
        store.apply(LoadResult(library: MusicLibrary(), errors: [SomeError()]))

        store.apply(LoadResult(library: library, errors: []))

        #expect(!store.loadDidFail)
    }
}
