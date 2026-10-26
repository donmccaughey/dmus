import Foundation
import Testing

struct LoadMusicLibraryTests {
    let root = URL(filePath: "/Music", directoryHint: .isDirectory)

    func load(_ fileSystem: FakeFileSystem) -> MusicLibrary {
        loadMusicLibrary(musicRootDirectory: root, fileSystem: fileSystem)
    }

    func track(_ name: String, path: String, album: String? = nil, artist: String? = nil) -> FolderChild {
        .track(Track(
            trackName: name,
            albumName: album ?? Track.noAlbum,
            artistName: artist ?? Track.noArtist,
            path: path
        ))
    }

    // Notifications are posted on the main actor after loadMusicLibrary()
    // returns, and NotificationCenter.default is shared with tests running in
    // parallel, so wait for the notification carrying our own object.
    func nextNotification(
        from notifications: NotificationCenter.Notifications,
        where matches: (Notification) -> Bool
    ) async -> Notification? {
        for await notification in notifications where matches(notification) {
            return notification
        }
        return nil
    }

    func didLoad() -> NotificationCenter.Notifications {
        NotificationCenter.default.notifications(named: .musicLibraryDidLoad)
    }

    func loadDidFail() -> NotificationCenter.Notifications {
        NotificationCenter.default.notifications(named: .musicLibraryLoadDidFail)
    }

    func carries(_ library: MusicLibrary) -> (Notification) -> Bool {
        { ($0.object as? MusicLibrary)?.rootFolder == library.rootFolder }
    }

    func carries(_ error: FakeFileSystemError) -> (Notification) -> Bool {
        { $0.object as? FakeFileSystemError == error }
    }

    @Test func emptyDirectoryGivesEmptyLibrary() {
        let library = load(FakeFileSystem())

        #expect(library.isEmpty)
        #expect(library.rootFolder.path == "/Music")
        #expect(library.rootFolder.name == Folder.rootName)
        #expect(library.rootFolder.children.isEmpty)
    }

    @Test func tracksInRootHaveNoAlbumOrArtist() {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Song.mp3")

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            track("Song", path: "/Music/Song.mp3"),
        ])
    }

    @Test func folderNamesBecomeAlbumAndArtist() {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Artist", .directory)
        fileSystem.add("/Music/Artist/Album", .directory)
        fileSystem.add("/Music/Artist/Album/01 Song.mp3")

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            .folder(Folder(path: "/Music/Artist", name: "Artist", children: [
                .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
                    track("01 Song", path: "/Music/Artist/Album/01 Song.mp3", album: "Album", artist: "Artist"),
                ])),
            ])),
        ])
    }

    @Test func trackInTopLevelFolderHasAlbumButNoArtist() {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Album", .directory)
        fileSystem.add("/Music/Album/Song.m4a")

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            .folder(Folder(path: "/Music/Album", name: "Album", children: [
                track("Song", path: "/Music/Album/Song.m4a", album: "Album"),
            ])),
        ])
    }

    @Test func deeperFoldersUseNearestTwoAncestors() throws {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Genre", .directory)
        fileSystem.add("/Music/Genre/Artist", .directory)
        fileSystem.add("/Music/Genre/Artist/Album", .directory)
        fileSystem.add("/Music/Genre/Artist/Album/Song.mp3")

        let library = load(fileSystem)

        let genre = try #require(library.rootFolder.children.first?.children)
        let artist = try #require(genre.first?.children)
        let album = try #require(artist.first?.children)
        #expect(album == [
            track("Song", path: "/Music/Genre/Artist/Album/Song.mp3", album: "Album", artist: "Artist"),
        ])
    }

    @Test func onlyMusicFilesBecomeTracks() {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/cover.jpg")
        fileSystem.add("/Music/notes.txt")
        fileSystem.add("/Music/README")
        fileSystem.add("/Music/Loud.MP3")
        fileSystem.add("/Music/Quiet.M4A")

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            track("Loud", path: "/Music/Loud.MP3"),
            track("Quiet", path: "/Music/Quiet.M4A"),
        ])
    }

    @Test func packagesAreSkipped() {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Music Library.musiclibrary", .package)
        fileSystem.add("/Music/Music Library.musiclibrary/Song.mp3")
        fileSystem.add("/Music/Song.mp3")

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            track("Song", path: "/Music/Song.mp3"),
        ])
    }

    @Test func entriesThatAreNeitherFilesNorDirectoriesAreSkipped() {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Link.mp3", .other)
        fileSystem.add("/Music/Song.mp3")

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            track("Song", path: "/Music/Song.mp3"),
        ])
    }

    @Test func localizedNamesAreUsedForDisplay() {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Musica", .directory, localizedName: "Música")
        fileSystem.add("/Music/Musica/Hidden.mp3", localizedName: "Hidden")
        fileSystem.add("/Music/Musica/Shown.mp3", localizedName: "Shown.mp3")

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            .folder(Folder(path: "/Music/Musica", name: "Música", children: [
                track("Hidden", path: "/Music/Musica/Hidden.mp3", album: "Música"),
                track("Shown", path: "/Music/Musica/Shown.mp3", album: "Música"),
            ])),
        ])
    }

    @Test func childrenAreSortedNaturallyByName() {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Track 10.mp3")
        fileSystem.add("/Music/track 2.mp3")
        fileSystem.add("/Music/B folder", .directory)
        fileSystem.add("/Music/a folder", .directory)

        let library = load(fileSystem)

        #expect(library.rootFolder.children.map(\.name) == [
            "a folder", "B folder", "track 2", "Track 10",
        ])
    }

    @Test(.timeLimit(.minutes(1)))
    func unlistableRootGivesEmptyLibraryAndPostsFailure() async {
        var fileSystem = FakeFileSystem()
        fileSystem.unlistableDirectories = ["/Music"]
        let failures = loadDidFail()
        let loads = didLoad()

        let library = load(fileSystem)

        #expect(library.isEmpty)
        #expect(library.rootFolder.path == "/Music")
        let failure = await nextNotification(from: failures, where: carries(FakeFileSystemError(path: "/Music")))
        #expect(failure != nil)
        let loaded = await nextNotification(from: loads, where: carries(library))
        #expect(loaded != nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func unlistableSubfolderBecomesEmptyFolder() async {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Broken", .directory)
        fileSystem.add("/Music/Song.mp3")
        fileSystem.unlistableDirectories = ["/Music/Broken"]
        let failures = loadDidFail()

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            .folder(Folder(path: "/Music/Broken", name: "Broken", children: [])),
            track("Song", path: "/Music/Song.mp3"),
        ])
        let failure = await nextNotification(from: failures, where: carries(FakeFileSystemError(path: "/Music/Broken")))
        #expect(failure != nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func unreadableEntryIsSkipped() async {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Bad.mp3")
        fileSystem.add("/Music/Good.mp3")
        fileSystem.unreadableEntries = ["/Music/Bad.mp3"]
        let failures = loadDidFail()

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            track("Good", path: "/Music/Good.mp3"),
        ])
        let failure = await nextNotification(from: failures, where: carries(FakeFileSystemError(path: "/Music/Bad.mp3")))
        #expect(failure != nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func postsDidLoadWithLibrary() async {
        var fileSystem = FakeFileSystem()
        fileSystem.add("/Music/Song.mp3")
        let loads = didLoad()

        let library = load(fileSystem)

        let loaded = await nextNotification(from: loads, where: carries(library))
        #expect(loaded != nil)
    }
}
