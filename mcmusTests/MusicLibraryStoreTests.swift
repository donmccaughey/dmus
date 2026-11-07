import Foundation
import Model
import Testing
import WrappersTestSupport

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

        store.loadInBackground(isDemo: false)
        await store.loadTask?.value

        #expect(store.musicRootDirectory?.url.path == "/Saved/Music")
        #expect(!store.loadDidFail)
        #expect(trackNames(in: store) == ["Song"])
    }

    @Test func backgroundLoadReportsLocateFailure() async {
        let store = MusicLibraryStore(fileSystem: FileSystemFake(), preferences: PreferencesFake())

        store.loadInBackground(isDemo: false)
        await store.loadTask?.value

        #expect(store.musicRootDirectory == nil)
        #expect(store.loadDidFail)
        #expect(store.library.isEmpty)
    }

    @Test func changingRootSavesBookmarkSwapsAccessAndReloads() async {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Saved/Music/Old.mp3")
        fileSystem.addPath("/Other/Music/New.mp3")
        let preferences = PreferencesFake(musicRootDirectoryBookmark: FileSystemFake.bookmark(forPath: "/Saved/Music"))
        let store = MusicLibraryStore(fileSystem: fileSystem, preferences: preferences)
        store.loadInBackground(isDemo: false)
        await store.loadTask?.value

        store.changeMusicRootDirectory(to: URL(filePath: "/Other/Music", directoryHint: .isDirectory))

        #expect(preferences.musicRootDirectoryBookmark == FileSystemFake.bookmark(forPath: "/Other/Music"))
        #expect(fileSystem.stopped == ["/Saved/Music"])
        #expect(fileSystem.started == ["/Saved/Music", "/Other/Music"])
        #expect(store.musicRootDirectory?.url.path == "/Other/Music")

        await store.loadTask?.value

        #expect(!store.loadDidFail)
        #expect(trackNames(in: store) == ["New"])
    }

    @Test func changingRootPostsRootChangeFirstAndLibraryChangeWhenLoaded() async {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Other/Music/New.mp3")
        let preferences = PreferencesFake(musicRootDirectoryBookmark: FileSystemFake.bookmark(forPath: "/Saved/Music"))
        let store = MusicLibraryStore(fileSystem: fileSystem, preferences: preferences)
        store.loadInBackground(isDemo: false)
        await store.loadTask?.value
        let rootChanges = NotificationCounter(name: MusicLibraryStore.musicRootDirectoryDidChangeNotification, object: store)
        let libraryChanges = NotificationCounter(name: MusicLibraryStore.libraryDidChangeNotification, object: store)

        store.changeMusicRootDirectory(to: URL(filePath: "/Other/Music", directoryHint: .isDirectory))

        #expect(rootChanges.count == 1)
        #expect(libraryChanges.count == 0)

        await store.loadTask?.value

        #expect(libraryChanges.count == 1)
    }

    @Test func choosingCurrentRootAgainDoesNothing() async {
        let preferences = PreferencesFake(musicRootDirectoryBookmark: FileSystemFake.bookmark(forPath: "/Saved/Music"))
        let fileSystem = FileSystemFake()
        let store = MusicLibraryStore(fileSystem: fileSystem, preferences: preferences)
        store.loadInBackground(isDemo: false)
        await store.loadTask?.value
        let loadTask = store.loadTask
        preferences.musicRootDirectoryBookmark = nil

        store.changeMusicRootDirectory(to: URL(filePath: "/Saved/Music", directoryHint: .isDirectory))

        #expect(preferences.musicRootDirectoryBookmark == nil)
        #expect(fileSystem.stopped.isEmpty)
        #expect(store.loadTask == loadTask)
    }
    #endif
}
