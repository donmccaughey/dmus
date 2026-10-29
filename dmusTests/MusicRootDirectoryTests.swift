import Foundation
import Testing

#if os(macOS)
struct MusicRootDirectoryTests {
    @Test func usesSavedPathWhenPresent() throws {
        let preferences = PreferencesFake(musicRootDirectoryPath: "/Saved/Music")

        let url = try MusicRootDirectory.locate(fileSystem: FileSystemFake(), preferences: preferences)

        #expect(url.path == "/Saved/Music")
        #expect(url.hasDirectoryPath)
        #expect(preferences.musicRootDirectoryPath == "/Saved/Music")
    }

    @Test func initializesToSystemMusicDirectoryWhenAbsent() throws {
        let preferences = PreferencesFake()
        var fileSystem = FileSystemFake()
        fileSystem.musicDirectoryURL = URL(filePath: "/Users/me/Music", directoryHint: .isDirectory)

        let url = try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)

        #expect(url.path == "/Users/me/Music")
        #expect(preferences.musicRootDirectoryPath == "/Users/me/Music")
    }

    @Test func failsWhenSystemMusicDirectoryIsUnavailable() {
        let preferences = PreferencesFake()

        #expect(throws: FileSystemFakeError(path: "getMusicDirectoryURL")) {
            try MusicRootDirectory.locate(fileSystem: FileSystemFake(), preferences: preferences)
        }
        #expect(preferences.musicRootDirectoryPath == nil)
    }

    @Test func createsSavedDirectory() {
        let preferences = PreferencesFake(musicRootDirectoryPath: "/Saved/Music")
        var fileSystem = FileSystemFake()
        fileSystem.uncreatableDirectories = ["/Saved/Music"]

        #expect(throws: FileSystemFakeError(path: "/Saved/Music")) {
            try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)
        }
    }
}
#endif
