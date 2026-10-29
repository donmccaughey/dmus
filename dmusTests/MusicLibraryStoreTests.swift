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

    #if os(macOS)
    func trackNames(in store: MusicLibraryStore) -> [String] {
        store.library.rootFolder.children.compactMap {
            if case .track(let track) = $0 { track.trackName } else { nil }
        }
    }

    @Test func backgroundLoadLocatesRootAndLoadsLibrary() async {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Saved/Music/Song.mp3")
        let preferences = FakePreferences(musicRootDirectoryPath: "/Saved/Music")
        let store = MusicLibraryStore(fileSystem: fileSystem, preferences: preferences)

        store.loadInBackground(isDemo: false)
        await store.loadTask?.value

        #expect(store.musicRootDirectory?.path == "/Saved/Music")
        #expect(!store.loadDidFail)
        #expect(trackNames(in: store) == ["Song"])
    }

    @Test func backgroundLoadReportsLocateFailure() async {
        let store = MusicLibraryStore(fileSystem: FakeFileSystem(), preferences: FakePreferences())

        store.loadInBackground(isDemo: false)
        await store.loadTask?.value

        #expect(store.musicRootDirectory == nil)
        #expect(store.loadDidFail)
        #expect(store.library.isEmpty)
    }

    @Test func changingRootSavesPreferenceAndReloads() async {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Saved/Music/Old.mp3")
        fileSystem.add("/Other/Music/New.mp3")
        let preferences = FakePreferences(musicRootDirectoryPath: "/Saved/Music")
        let store = MusicLibraryStore(fileSystem: fileSystem, preferences: preferences)
        store.loadInBackground(isDemo: false)
        await store.loadTask?.value

        store.changeMusicRootDirectory(to: URL(filePath: "/Other/Music", directoryHint: .isDirectory))

        #expect(preferences.musicRootDirectoryPath == "/Other/Music")
        #expect(store.musicRootDirectory?.path == "/Other/Music")

        await store.loadTask?.value

        #expect(!store.loadDidFail)
        #expect(trackNames(in: store) == ["New"])
    }

    @Test func choosingCurrentRootAgainDoesNothing() async {
        let preferences = FakePreferences(musicRootDirectoryPath: "/Saved/Music")
        let store = MusicLibraryStore(fileSystem: FakeFileSystem(), preferences: preferences)
        store.loadInBackground(isDemo: false)
        await store.loadTask?.value
        let loadTask = store.loadTask
        preferences.musicRootDirectoryPath = nil

        store.changeMusicRootDirectory(to: URL(filePath: "/Saved/Music", directoryHint: .isDirectory))

        #expect(preferences.musicRootDirectoryPath == nil)
        #expect(store.loadTask == loadTask)
    }
    #endif
}
