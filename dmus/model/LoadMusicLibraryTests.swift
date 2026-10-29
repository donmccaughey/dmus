import Foundation
import Testing

struct LoadMusicLibraryTests {
    let root = URL(filePath: "/Music", directoryHint: .isDirectory)

    func loadResult(_ fileSystem: FileSystemFake) -> LoadResult {
        loadMusicLibrary(musicRootDirectory: root, fileSystem: fileSystem)
    }

    func load(_ fileSystem: FileSystemFake) -> MusicLibrary {
        loadResult(fileSystem).library
    }

    func track(_ name: String, path: String, album: String? = nil, artist: String? = nil) -> FolderChild {
        .track(Track(
            trackName: name,
            albumName: album ?? Track.noAlbum,
            artistName: artist ?? Track.noArtist,
            path: path
        ))
    }

    func fakeErrors(in result: LoadResult) -> [FileSystemFakeError] {
        result.errors.compactMap { $0 as? FileSystemFakeError }
    }

    @Test func emptyDirectoryGivesEmptyLibrary() {
        let library = load(FileSystemFake())

        #expect(library.isEmpty)
        #expect(library.rootFolder.path == "/Music")
        #expect(library.rootFolder.name == Folder.rootName)
        #expect(library.rootFolder.children.isEmpty)
    }

    @Test func tracksInRootHaveNoAlbumOrArtist() {
        var fileSystem = FileSystemFake()
        fileSystem.add("/Music/Song.mp3")

        let result = loadResult(fileSystem)

        #expect(result.library.rootFolder.children == [
            track("Song", path: "/Music/Song.mp3"),
        ])
        #expect(result.errors.isEmpty)
    }

    @Test func folderNamesBecomeAlbumAndArtist() {
        var fileSystem = FileSystemFake()
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
        var fileSystem = FileSystemFake()
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
        var fileSystem = FileSystemFake()
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
        var fileSystem = FileSystemFake()
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
        var fileSystem = FileSystemFake()
        fileSystem.add("/Music/Music Library.musiclibrary", .package)
        fileSystem.add("/Music/Music Library.musiclibrary/Song.mp3")
        fileSystem.add("/Music/Song.mp3")

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            track("Song", path: "/Music/Song.mp3"),
        ])
    }

    @Test func entriesThatAreNeitherFilesNorDirectoriesAreSkipped() {
        var fileSystem = FileSystemFake()
        fileSystem.add("/Music/Link.mp3", .other)
        fileSystem.add("/Music/Song.mp3")

        let library = load(fileSystem)

        #expect(library.rootFolder.children == [
            track("Song", path: "/Music/Song.mp3"),
        ])
    }

    @Test func localizedNamesAreUsedForDisplay() {
        var fileSystem = FileSystemFake()
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
        var fileSystem = FileSystemFake()
        fileSystem.add("/Music/Track 10.mp3")
        fileSystem.add("/Music/track 2.mp3")
        fileSystem.add("/Music/B folder", .directory)
        fileSystem.add("/Music/a folder", .directory)

        let library = load(fileSystem)

        #expect(library.rootFolder.children.map(\.name) == [
            "a folder", "B folder", "track 2", "Track 10",
        ])
    }

    @Test func unlistableRootGivesEmptyLibraryAndReportsFailure() {
        var fileSystem = FileSystemFake()
        fileSystem.unlistableDirectories = ["/Music"]

        let result = loadResult(fileSystem)

        #expect(result.library.isEmpty)
        #expect(result.library.rootFolder.path == "/Music")
        #expect(result.errors.count == 1)
        #expect(fakeErrors(in: result) == [FileSystemFakeError(path: "/Music")])
    }

    @Test func unlistableSubfolderBecomesEmptyFolderAndReportsFailure() {
        var fileSystem = FileSystemFake()
        fileSystem.add("/Music/Broken", .directory)
        fileSystem.add("/Music/Song.mp3")
        fileSystem.unlistableDirectories = ["/Music/Broken"]

        let result = loadResult(fileSystem)

        #expect(result.library.rootFolder.children == [
            .folder(Folder(path: "/Music/Broken", name: "Broken", children: [])),
            track("Song", path: "/Music/Song.mp3"),
        ])
        #expect(result.errors.count == 1)
        #expect(fakeErrors(in: result) == [FileSystemFakeError(path: "/Music/Broken")])
    }

    @Test func unreadableEntryIsSkippedAndReportsFailure() {
        var fileSystem = FileSystemFake()
        fileSystem.add("/Music/Bad.mp3")
        fileSystem.add("/Music/Good.mp3")
        fileSystem.unreadableEntries = ["/Music/Bad.mp3"]

        let result = loadResult(fileSystem)

        #expect(result.library.rootFolder.children == [
            track("Good", path: "/Music/Good.mp3"),
        ])
        #expect(result.errors.count == 1)
        #expect(fakeErrors(in: result) == [FileSystemFakeError(path: "/Music/Bad.mp3")])
    }
}
