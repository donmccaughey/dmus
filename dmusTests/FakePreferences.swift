import Foundation

nonisolated final class FakePreferences: Preferences, @unchecked Sendable {
    var musicRootDirectoryPath: String?

    init(musicRootDirectoryPath: String? = nil) {
        self.musicRootDirectoryPath = musicRootDirectoryPath
    }

    func getMusicRootDirectoryPath() -> String? {
        musicRootDirectoryPath
    }

    func setMusicRootDirectoryPath(_ path: String) {
        musicRootDirectoryPath = path
    }
}
