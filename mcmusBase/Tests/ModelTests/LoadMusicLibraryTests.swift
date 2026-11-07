import Foundation
import Model
import Testing
import WrappersTestSupport

struct LoadMusicLibraryTests {
    let root = URL(filePath: "/Music", directoryHint: .isDirectory)

    func loadResult(_ fileSystem: FileSystemFake) -> LoadResult {
        loadMusicLibrary(musicRootDirectory: root, fileSystem: fileSystem)
    }

    func load(_ fileSystem: FileSystemFake) -> MusicLibrary {
        loadResult(fileSystem).library
    }

    func track(_ name: String, path: String, album: String? = nil, artist: String? = nil) -> Track {
        Track(
            trackName: name,
            albumName: album ?? Track.noAlbum,
            artistName: artist ?? Track.noArtist,
            path: path
        )
    }


    @Test func emptyDirectoryGivesEmptyLibrary() {
        let library = load(FileSystemFake())

        #expect(library.isEmpty)
        #expect(library.rootFolder.path == "/Music")
        #expect(library.rootFolder.name == Folder.rootName)
        #expect(library.rootFolder.children.isEmpty)
    }

    @Test func tracksInRootHaveNoAlbumOrArtist() {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/Song.mp3")

        let result = loadResult(fileSystem)

        #expect(childrenEqual(result.library.rootFolder.children, [
            track("Song", path: "/Music/Song.mp3"),
        ]))
        #expect(result.errors.isEmpty)
    }

    @Test func folderNamesBecomeAlbumAndArtist() {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/Artist", kind: .directory)
        fileSystem.addPath("/Music/Artist/Album", kind: .directory)
        fileSystem.addPath("/Music/Artist/Album/01 Song.mp3")

        let library = load(fileSystem)

        #expect(childrenEqual(library.rootFolder.children, [
            Folder(path: "/Music/Artist", name: "Artist", children: [
                Folder(path: "/Music/Artist/Album", name: "Album", children: [
                    track("01 Song", path: "/Music/Artist/Album/01 Song.mp3", album: "Album", artist: "Artist"),
                ]),
            ]),
        ]))
    }

    @Test func trackInTopLevelFolderHasAlbumButNoArtist() {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/Album", kind: .directory)
        fileSystem.addPath("/Music/Album/Song.m4a")

        let library = load(fileSystem)

        #expect(childrenEqual(library.rootFolder.children, [
            Folder(path: "/Music/Album", name: "Album", children: [
                track("Song", path: "/Music/Album/Song.m4a", album: "Album"),
            ]),
        ]))
    }

    @Test func deeperFoldersUseNearestTwoAncestors() throws {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/Genre", kind: .directory)
        fileSystem.addPath("/Music/Genre/Artist", kind: .directory)
        fileSystem.addPath("/Music/Genre/Artist/Album", kind: .directory)
        fileSystem.addPath("/Music/Genre/Artist/Album/Song.mp3")

        let library = load(fileSystem)

        let genre = try #require(library.rootFolder.children.first?.children)
        let artist = try #require(genre.first?.children)
        let album = try #require(artist.first?.children)
        #expect(childrenEqual(album, [
            track("Song", path: "/Music/Genre/Artist/Album/Song.mp3", album: "Album", artist: "Artist"),
        ]))
    }

    @Test func onlyMusicFilesBecomeTracks() {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/cover.jpg")
        fileSystem.addPath("/Music/notes.txt")
        fileSystem.addPath("/Music/README")
        fileSystem.addPath("/Music/Loud.MP3")
        fileSystem.addPath("/Music/Quiet.M4A")

        let library = load(fileSystem)

        #expect(childrenEqual(library.rootFolder.children, [
            track("Loud", path: "/Music/Loud.MP3"),
            track("Quiet", path: "/Music/Quiet.M4A"),
        ]))
    }

    @Test func packagesAreSkipped() {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/Music Library.musiclibrary", kind: .package)
        fileSystem.addPath("/Music/Music Library.musiclibrary/Song.mp3")
        fileSystem.addPath("/Music/Song.mp3")

        let library = load(fileSystem)

        #expect(childrenEqual(library.rootFolder.children, [
            track("Song", path: "/Music/Song.mp3"),
        ]))
    }

    @Test func entriesThatAreNeitherFilesNorDirectoriesAreSkipped() {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/Link.mp3", kind: .other)
        fileSystem.addPath("/Music/Song.mp3")

        let library = load(fileSystem)

        #expect(childrenEqual(library.rootFolder.children, [
            track("Song", path: "/Music/Song.mp3"),
        ]))
    }

    @Test func localizedNamesAreUsedForDisplay() {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/Musica", kind: .directory, localizedName: "Música")
        fileSystem.addPath("/Music/Musica/Hidden.mp3", kind: .file, localizedName: "Hidden")
        fileSystem.addPath("/Music/Musica/Shown.mp3", kind: .file, localizedName: "Shown.mp3")

        let library = load(fileSystem)

        #expect(childrenEqual(library.rootFolder.children, [
            Folder(path: "/Music/Musica", name: "Música", children: [
                track("Hidden", path: "/Music/Musica/Hidden.mp3", album: "Música"),
                track("Shown", path: "/Music/Musica/Shown.mp3", album: "Música"),
            ]),
        ]))
    }

    @Test func childrenAreSortedNaturallyByName() {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/Track 10.mp3")
        fileSystem.addPath("/Music/track 2.mp3")
        fileSystem.addPath("/Music/B folder", kind: .directory)
        fileSystem.addPath("/Music/a folder", kind: .directory)

        let library = load(fileSystem)

        #expect(library.rootFolder.children.map(\.name) == [
            "a folder", "B folder", "track 2", "Track 10",
        ])
    }

    @Test func unlistableRootGivesEmptyLibraryAndReportsFailure() {
        let fileSystem = FileSystemFake()
        fileSystem.unlistableDirectories = ["/Music"]

        let result = loadResult(fileSystem)

        #expect(result.library.isEmpty)
        #expect(result.library.rootFolder.path == "/Music")
        #expect(result.errors.count == 1)
        #expect(fileSystemFakeErrorPaths(in: result.errors) == ["/Music"])
    }

    @Test func unlistableSubfolderBecomesEmptyFolderAndReportsFailure() {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/Broken", kind: .directory)
        fileSystem.addPath("/Music/Song.mp3")
        fileSystem.unlistableDirectories = ["/Music/Broken"]

        let result = loadResult(fileSystem)

        #expect(childrenEqual(result.library.rootFolder.children, [
            Folder(path: "/Music/Broken", name: "Broken", children: []),
            track("Song", path: "/Music/Song.mp3"),
        ]))
        #expect(result.errors.count == 1)
        #expect(fileSystemFakeErrorPaths(in: result.errors) == ["/Music/Broken"])
    }

    @Test func unreadableEntryIsSkippedAndReportsFailure() {
        let fileSystem = FileSystemFake()
        fileSystem.addPath("/Music/Bad.mp3")
        fileSystem.addPath("/Music/Good.mp3")
        fileSystem.unreadableEntries = ["/Music/Bad.mp3"]

        let result = loadResult(fileSystem)

        #expect(childrenEqual(result.library.rootFolder.children, [
            track("Good", path: "/Music/Good.mp3"),
        ]))
        #expect(result.errors.count == 1)
        #expect(fileSystemFakeErrorPaths(in: result.errors) == ["/Music/Bad.mp3"])
    }
}
