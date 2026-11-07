import Foundation
import Testing

struct MusicLibraryStoreTests {
    struct SomeError: Error {}

    let library = MusicLibrary(rootFolder: Folder(path: "/Music", name: Folder.rootName, children: [
        Track(trackName: "Song", albumName: Track.noAlbum, artistName: Track.noArtist, path: "/Music/Song.mp3"),
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

    @Test func applyingResultPostsLibraryDidChange() {
        let store = MusicLibraryStore()
        let libraryChanges = NotificationCounter(name: MusicLibraryStore.libraryDidChangeNotification, object: store)
        let rootChanges = NotificationCounter(name: MusicLibraryStore.musicRootDirectoryDidChangeNotification, object: store)

        store.apply(LoadResult(library: library, errors: []))

        #expect(libraryChanges.count == 1)
        #expect(rootChanges.count == 0)
    }

    #if os(macOS)
    func trackNames(in store: MusicLibraryStore) -> [String] {
        store.library.rootFolder.children.compactMap { ($0 as? Track)?.trackName }
    }

    @Test func backgroundLoadLocatesRootAndLoadsLibrary() async {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Saved/Music/Song.mp3")
        let preferences = PreferencesFake(musicRootDirectoryBookmark: FileSystemFake.bookmark(forPath: "/Saved/Music"))
        let store = MusicLibraryStore(fileSystem: fileSystem, preferences: preferences)

        await store.loadInBackgroundAndWait(isDemo: false)

        #expect(store.musicRootDirectory?.url.path == "/Saved/Music")
        #expect(!store.loadDidFail)
        #expect(trackNames(in: store) == ["Song"])
    }

    @Test func backgroundLoadReportsLocateFailure() async {
        let store = MusicLibraryStore(fileSystem: FileSystemFake(), preferences: PreferencesFake())

        await store.loadInBackgroundAndWait(isDemo: false)

        #expect(store.musicRootDirectory == nil)
        #expect(store.loadDidFail)
        #expect(store.library.isEmpty)
        #expect(store.loadErrors.map { fileSystemFakeErrorPath(of: $0) } == ["getMusicDirectoryURL"])
    }

    @Test func changingRootSavesBookmarkSwapsAccessAndReloads() async {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Saved/Music/Old.mp3")
        fileSystem.addPath("/Other/Music/New.mp3")
        let preferences = PreferencesFake(musicRootDirectoryBookmark: FileSystemFake.bookmark(forPath: "/Saved/Music"))
        let store = MusicLibraryStore(fileSystem: fileSystem, preferences: preferences)
        await store.loadInBackgroundAndWait(isDemo: false)

        // The root changes before the call returns; the library follows when
        // the load lands.
        await withCheckedContinuation { loaded in
            store.changeMusicRootDirectory(to: URL(filePath: "/Other/Music", directoryHint: .isDirectory)) {
                loaded.resume()
            }

            #expect(preferences.musicRootDirectoryBookmark == FileSystemFake.bookmark(forPath: "/Other/Music"))
            #expect(fileSystem.stopped == ["/Saved/Music"])
            #expect(fileSystem.started == ["/Saved/Music", "/Other/Music"])
            #expect(store.musicRootDirectory?.url.path == "/Other/Music")
            #expect(trackNames(in: store) == ["Old"])
        }

        #expect(!store.loadDidFail)
        #expect(trackNames(in: store) == ["New"])
    }

    @Test func changingRootPostsRootChangeFirstAndLibraryChangeWhenLoaded() async {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Other/Music/New.mp3")
        let preferences = PreferencesFake(musicRootDirectoryBookmark: FileSystemFake.bookmark(forPath: "/Saved/Music"))
        let store = MusicLibraryStore(fileSystem: fileSystem, preferences: preferences)
        await store.loadInBackgroundAndWait(isDemo: false)
        let rootChanges = NotificationCounter(name: MusicLibraryStore.musicRootDirectoryDidChangeNotification, object: store)
        let libraryChanges = NotificationCounter(name: MusicLibraryStore.libraryDidChangeNotification, object: store)

        await withCheckedContinuation { loaded in
            store.changeMusicRootDirectory(to: URL(filePath: "/Other/Music", directoryHint: .isDirectory)) {
                loaded.resume()
            }

            #expect(rootChanges.count == 1)
            #expect(libraryChanges.count == 0)
        }

        #expect(libraryChanges.count == 1)
    }

    @Test func choosingCurrentRootAgainDoesNothing() async {
        let preferences = PreferencesFake(musicRootDirectoryBookmark: FileSystemFake.bookmark(forPath: "/Saved/Music"))
        let fileSystem = FileSystemFake()
        let store = MusicLibraryStore(fileSystem: fileSystem, preferences: preferences)
        await store.loadInBackgroundAndWait(isDemo: false)
        let libraryChanges = NotificationCounter(name: MusicLibraryStore.libraryDidChangeNotification, object: store)
        preferences.musicRootDirectoryBookmark = nil

        await store.changeMusicRootDirectoryAndWait(to: URL(filePath: "/Saved/Music", directoryHint: .isDirectory))

        #expect(preferences.musicRootDirectoryBookmark == nil)
        #expect(fileSystem.stopped.isEmpty)
        #expect(libraryChanges.count == 0)
    }
    #endif
}

// The store reports completion through a handler, which an Objective-C caller
// can take; these wrap it for tests that await the load.
extension MusicLibraryStore {
    func loadInBackgroundAndWait(isDemo: Bool) async {
        await withCheckedContinuation { loaded in
            loadInBackground(isDemo: isDemo) { loaded.resume() }
        }
    }

    #if os(macOS)
    func changeMusicRootDirectoryAndWait(to url: URL) async {
        await withCheckedContinuation { loaded in
            changeMusicRootDirectory(to: url) { loaded.resume() }
        }
    }
    #endif
}
