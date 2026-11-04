import Foundation
import Model
import Testing
import WrappersTestSupport

#if os(macOS)
struct MusicRootDirectoryTests {
    let savedBookmark = FileSystemFake.bookmark(for: "/Saved/Music")
    let systemMusicDirectory = URL(filePath: "/Users/me/Music", directoryHint: .isDirectory)

    @Test func usesResolvedBookmarkAndStartsAccess() throws {
        let preferences = PreferencesFake(musicRootDirectoryBookmark: savedBookmark)
        let fileSystem = FileSystemFake()

        let root = try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)

        #expect(root.url.path == "/Saved/Music")
        #expect(root.url.hasDirectoryPath)
        #expect(root.isSecurityScoped)
        #expect(fileSystem.log.started == ["/Saved/Music"])
        #expect(fileSystem.log.bookmarked.isEmpty)
        #expect(preferences.musicRootDirectoryBookmark == savedBookmark)
    }

    @Test func refreshesStaleBookmark() throws {
        let preferences = PreferencesFake(musicRootDirectoryBookmark: savedBookmark)
        var fileSystem = FileSystemFake()
        fileSystem.staleBookmarks = ["/Saved/Music"]

        let root = try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)

        #expect(root.url.path == "/Saved/Music")
        #expect(root.isSecurityScoped)
        #expect(fileSystem.log.bookmarked == ["/Saved/Music"])
        #expect(preferences.musicRootDirectoryBookmark == savedBookmark)
    }

    @Test func fallsBackToSystemMusicDirectoryWhenBookmarkDoesNotResolve() throws {
        let preferences = PreferencesFake(musicRootDirectoryBookmark: savedBookmark)
        var fileSystem = FileSystemFake()
        fileSystem.unresolvableBookmarks = ["/Saved/Music"]
        fileSystem.musicDirectoryURL = systemMusicDirectory

        let root = try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)

        #expect(root.url.path == "/Users/me/Music")
        #expect(!root.isSecurityScoped)
        #expect(fileSystem.log.started.isEmpty)
        #expect(preferences.musicRootDirectoryBookmark == savedBookmark)
    }

    @Test func fallsBackToSystemMusicDirectoryWhenAccessIsDenied() throws {
        let preferences = PreferencesFake(musicRootDirectoryBookmark: savedBookmark)
        var fileSystem = FileSystemFake()
        fileSystem.inaccessiblePaths = ["/Saved/Music"]
        fileSystem.musicDirectoryURL = systemMusicDirectory

        let root = try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)

        #expect(root.url.path == "/Users/me/Music")
        #expect(!root.isSecurityScoped)
        #expect(fileSystem.log.started.isEmpty)
    }

    @Test func usesSystemMusicDirectoryWhenNoBookmarkIsSaved() throws {
        let preferences = PreferencesFake()
        var fileSystem = FileSystemFake()
        fileSystem.musicDirectoryURL = systemMusicDirectory

        let root = try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)

        #expect(root.url.path == "/Users/me/Music")
        #expect(!root.isSecurityScoped)
        #expect(fileSystem.log.started.isEmpty)
        #expect(preferences.musicRootDirectoryBookmark == nil)
    }

    @Test func failsWhenSystemMusicDirectoryIsUnavailable() {
        let preferences = PreferencesFake()

        #expect(throws: FileSystemFakeError(path: "getMusicDirectoryURL")) {
            try MusicRootDirectory.locate(fileSystem: FileSystemFake(), preferences: preferences)
        }
        #expect(preferences.musicRootDirectoryBookmark == nil)
    }

    @Test func choosingSavesBookmarkAndStartsAccess() {
        let preferences = PreferencesFake()
        let fileSystem = FileSystemFake()
        let chosen = URL(filePath: "/Other/Music", directoryHint: .isDirectory)

        let root = MusicRootDirectory.choose(chosen, fileSystem: fileSystem, preferences: preferences)

        #expect(root.url.path == "/Other/Music")
        #expect(root.isSecurityScoped)
        #expect(preferences.musicRootDirectoryBookmark == FileSystemFake.bookmark(for: "/Other/Music"))
        #expect(fileSystem.log.started == ["/Other/Music"])
    }

    @Test func choosingKeepsSessionAccessWhenBookmarkCannotBeMade() {
        let preferences = PreferencesFake()
        var fileSystem = FileSystemFake()
        fileSystem.unbookmarkablePaths = ["/Other/Music"]
        let chosen = URL(filePath: "/Other/Music", directoryHint: .isDirectory)

        let root = MusicRootDirectory.choose(chosen, fileSystem: fileSystem, preferences: preferences)

        #expect(root.url.path == "/Other/Music")
        #expect(!root.isSecurityScoped)
        #expect(preferences.musicRootDirectoryBookmark == nil)
        #expect(fileSystem.log.started.isEmpty)
    }

    @Test func stopAccessingStopsOnlySecurityScopedRoot() {
        let fileSystem = FileSystemFake()
        let url = URL(filePath: "/Saved/Music", directoryHint: .isDirectory)

        MusicRootDirectory(url: url, isSecurityScoped: false).stopAccessing(fileSystem: fileSystem)
        #expect(fileSystem.log.stopped.isEmpty)

        MusicRootDirectory(url: url, isSecurityScoped: true).stopAccessing(fileSystem: fileSystem)
        #expect(fileSystem.log.stopped == ["/Saved/Music"])
    }
}
#endif
