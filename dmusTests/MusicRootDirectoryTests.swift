import Foundation
import Testing

#if os(macOS)
struct MusicRootDirectoryTests {
    @Test func usesSavedPathWhenPresent() throws {
        let preferences = FakePreferences(musicRootDirectoryPath: "/Saved/Music")

        let url = try MusicRootDirectory.locate(fileSystem: FakeFileSystem(), preferences: preferences)

        #expect(url.path == "/Saved/Music")
        #expect(url.hasDirectoryPath)
        #expect(preferences.musicRootDirectoryPath == "/Saved/Music")
    }

    @Test func initializesToSystemMusicDirectoryWhenAbsent() throws {
        let preferences = FakePreferences()
        var fileSystem = FakeFileSystem()
        fileSystem.musicDirectoryURL = URL(filePath: "/Users/me/Music", directoryHint: .isDirectory)

        let url = try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)

        #expect(url.path == "/Users/me/Music")
        #expect(preferences.musicRootDirectoryPath == "/Users/me/Music")
    }

    @Test func failsWhenSystemMusicDirectoryIsUnavailable() {
        let preferences = FakePreferences()

        #expect(throws: FakeFileSystemError(path: "getMusicDirectoryURL")) {
            try MusicRootDirectory.locate(fileSystem: FakeFileSystem(), preferences: preferences)
        }
        #expect(preferences.musicRootDirectoryPath == nil)
    }

    @Test func createsSavedDirectory() {
        let preferences = FakePreferences(musicRootDirectoryPath: "/Saved/Music")
        var fileSystem = FakeFileSystem()
        fileSystem.uncreatableDirectories = ["/Saved/Music"]

        #expect(throws: FakeFileSystemError(path: "/Saved/Music")) {
            try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)
        }
    }
}
#endif
