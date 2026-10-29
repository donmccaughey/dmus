import Foundation
import Testing

struct LoadDemoMusicLibraryTests {
    let trackPath = "/Bundle/demo-track.mp3"

    func loadResult(_ json: String) -> LoadResult {
        loadDemoMusicLibrary(demoData: Data(json.utf8), trackPath: trackPath)
    }

    func load(_ json: String) -> MusicLibrary {
        loadResult(json).library
    }

    func track(_ name: String, album: String? = nil, artist: String? = nil) -> FolderChild {
        .track(Track(
            trackName: name,
            albumName: album ?? Track.noAlbum,
            artistName: artist ?? Track.noArtist,
            path: trackPath
        ))
    }

    @Test func rootDirectoryNameBecomesRootPath() {
        let library = load("""
        [{"type":"directory","name":"/Users/demo/Music","contents":[]}]
        """)

        #expect(library.isEmpty)
        #expect(library.rootFolder.path == "/Users/demo/Music")
        #expect(library.rootFolder.name == Folder.rootName)
    }

    @Test func rootDirectoryWithoutNameUsesSlash() {
        let result = loadResult("""
        [{"type":"directory","contents":[{"type":"file","name":"Song.mp3"}]}]
        """)

        #expect(result.library.rootFolder.path == "/")
        #expect(result.library.rootFolder.children == [track("Song")])
        #expect(result.errors.isEmpty)
    }

    @Test func rootDirectoryWithoutContentsGivesEmptyLibrary() {
        let library = load("""
        [{"type":"directory","name":"/Music"}]
        """)

        #expect(library.isEmpty)
        #expect(library.rootFolder.path == "/Music")
    }

    @Test func firstDirectoryEntryIsUsedAsRoot() {
        let library = load("""
        [
            {"type":"report","directories":1,"files":1},
            {"type":"directory","name":"/Music","contents":[{"type":"file","name":"Song.mp3"}]},
            {"type":"directory","name":"/Other","contents":[{"type":"file","name":"Other.mp3"}]}
        ]
        """)

        #expect(library.rootFolder.path == "/Music")
        #expect(library.rootFolder.children == [track("Song")])
    }

    @Test func everyTrackPointsAtTheDemoTrackFile() {
        let library = load("""
        [{"type":"directory","name":"/Music","contents":[
            {"type":"file","name":"One.mp3"},
            {"type":"directory","name":"Album","contents":[
                {"type":"file","name":"Two.m4a"}
            ]}
        ]}]
        """)

        #expect(library.rootFolder.children == [
            .folder(Folder(path: "/Music/Album", name: "Album", children: [
                track("Two", album: "Album"),
            ])),
            track("One"),
        ])
    }

    @Test func folderNamesBecomeAlbumAndArtist() {
        let library = load("""
        [{"type":"directory","name":"/Music","contents":[
            {"type":"directory","name":"Artist","contents":[
                {"type":"directory","name":"Album","contents":[
                    {"type":"file","name":"01 Song.mp3"}
                ]}
            ]}
        ]}]
        """)

        #expect(library.rootFolder.children == [
            .folder(Folder(path: "/Music/Artist", name: "Artist", children: [
                .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
                    track("01 Song", album: "Album", artist: "Artist"),
                ])),
            ])),
        ])
    }

    @Test func deeperFoldersUseNearestTwoAncestors() throws {
        let library = load("""
        [{"type":"directory","name":"/Music","contents":[
            {"type":"directory","name":"Genre","contents":[
                {"type":"directory","name":"Artist","contents":[
                    {"type":"directory","name":"Album","contents":[
                        {"type":"file","name":"Song.mp3"}
                    ]}
                ]}
            ]}
        ]}]
        """)

        let genre = try #require(library.rootFolder.children.first?.children)
        let artist = try #require(genre.first?.children)
        let album = try #require(artist.first?.children)
        #expect(album == [track("Song", album: "Album", artist: "Artist")])
    }

    @Test func onlyMusicFilesBecomeTracks() {
        let library = load("""
        [{"type":"directory","name":"/Music","contents":[
            {"type":"file","name":"cover.jpg"},
            {"type":"file","name":"notes.txt"},
            {"type":"file","name":"README"},
            {"type":"file","name":"Loud.MP3"},
            {"type":"file","name":"Quiet.M4A"}
        ]}]
        """)

        #expect(library.rootFolder.children == [
            track("Loud"),
            track("Quiet"),
        ])
    }

    @Test func hiddenFilesAndDirectoriesAreSkipped() {
        let library = load("""
        [{"type":"directory","name":"/Music","contents":[
            {"type":"file","name":".DS_Store"},
            {"type":"file","name":"._Song.mp3"},
            {"type":"directory","name":".hidden","contents":[
                {"type":"file","name":"Secret.mp3"}
            ]},
            {"type":"file","name":"Song.mp3"}
        ]}]
        """)

        #expect(library.rootFolder.children == [track("Song")])
    }

    @Test func iTunesLPPackagesAreSkipped() {
        let library = load("""
        [{"type":"directory","name":"/Music","contents":[
            {"type":"directory","name":"Album.itlp","contents":[
                {"type":"file","name":"Inside.mp3"}
            ]},
            {"type":"directory","name":"Loud.ITLP","contents":[]},
            {"type":"file","name":"Song.mp3"}
        ]}]
        """)

        #expect(library.rootFolder.children == [track("Song")])
    }

    @Test func entriesWithoutNamesAreSkipped() {
        let library = load("""
        [{"type":"directory","name":"/Music","contents":[
            {"type":"file"},
            {"type":"directory","contents":[{"type":"file","name":"Song.mp3"}]},
            {"type":"file","name":"Song.mp3"}
        ]}]
        """)

        #expect(library.rootFolder.children == [track("Song")])
    }

    @Test func entriesThatAreNeitherFilesNorDirectoriesAreSkipped() {
        let library = load("""
        [{"type":"directory","name":"/Music","contents":[
            {"type":"link","name":"Link.mp3"},
            {"type":"file","name":"Song.mp3"}
        ]}]
        """)

        #expect(library.rootFolder.children == [track("Song")])
    }

    @Test func childrenAreSortedNaturallyByName() {
        let library = load("""
        [{"type":"directory","name":"/Music","contents":[
            {"type":"file","name":"Track 10.mp3"},
            {"type":"file","name":"track 2.mp3"},
            {"type":"directory","name":"B folder","contents":[]},
            {"type":"directory","name":"a folder","contents":[]}
        ]}]
        """)

        #expect(library.rootFolder.children.map(\.name) == [
            "a folder", "B folder", "track 2", "Track 10",
        ])
    }

    @Test func invalidJSONGivesEmptyLibraryAndReportsFailure() {
        let result = loadResult("not json")

        #expect(result.library.isEmpty)
        #expect(result.library.rootFolder.path == nil)
        #expect(result.errors.count == 1)
        #expect(result.errors.first is DecodingError)
    }

    @Test func missingDirectoryEntryGivesEmptyLibraryAndReportsFailure() {
        let result = loadResult("""
        [{"type":"report","directories":0,"files":0}]
        """)

        #expect(result.library.isEmpty)
        #expect(result.library.rootFolder.path == nil)
        #expect(result.errors.count == 1)
        #expect(result.errors.first as? LoadDemoError == .noDirectoryEntry)
    }
}
