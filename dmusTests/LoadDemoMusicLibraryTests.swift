import Foundation
import Testing

struct LoadDemoMusicLibraryTests {
    let trackPath = "/Bundle/demo-track.mp3"

    func load(_ json: String) -> MusicLibrary {
        loadDemoMusicLibrary(demoData: Data(json.utf8), trackPath: trackPath)
    }

    func track(_ name: String, album: String? = nil, artist: String? = nil) -> FolderChild {
        .track(Track(
            trackName: name,
            albumName: album ?? Track.noAlbum,
            artistName: artist ?? Track.noArtist,
            path: trackPath
        ))
    }

    // Notifications are posted on the main actor after loadDemoMusicLibrary()
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

    @Test func rootDirectoryNameBecomesRootPath() {
        let library = load("""
        [{"type":"directory","name":"/Users/demo/Music","contents":[]}]
        """)

        #expect(library.isEmpty)
        #expect(library.rootFolder.path == "/Users/demo/Music")
        #expect(library.rootFolder.name == Folder.rootName)
    }

    @Test func rootDirectoryWithoutNameUsesSlash() {
        let library = load("""
        [{"type":"directory","contents":[{"type":"file","name":"Song.mp3"}]}]
        """)

        #expect(library.rootFolder.path == "/")
        #expect(library.rootFolder.children == [track("Song")])
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

    @Test(.timeLimit(.minutes(1)))
    func invalidJSONGivesEmptyLibraryAndPostsFailure() async {
        let failures = loadDidFail()

        let library = load("not json")

        #expect(library.isEmpty)
        #expect(library.rootFolder.path == nil)
        let failure = await nextNotification(from: failures, where: { $0.object is DecodingError })
        #expect(failure != nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func missingDirectoryEntryGivesEmptyLibraryAndPostsFailure() async {
        let failures = loadDidFail()

        let library = load("""
        [{"type":"report","directories":0,"files":0}]
        """)

        #expect(library.isEmpty)
        #expect(library.rootFolder.path == nil)
        let failure = await nextNotification(from: failures, where: {
            $0.object as? LoadDemoError == .noDirectoryEntry
        })
        #expect(failure != nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func postsDidLoadWithLibrary() async {
        let loads = didLoad()

        let library = load("""
        [{"type":"directory","name":"/Music","contents":[{"type":"file","name":"Song.mp3"}]}]
        """)

        let loaded = await nextNotification(from: loads, where: carries(library))
        #expect(loaded != nil)
    }
}
