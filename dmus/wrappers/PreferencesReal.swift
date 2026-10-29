import Foundation

nonisolated struct PreferencesReal: Preferences {
    private static let musicRootDirectoryKey = "musicRootDirectory"

    func getMusicRootDirectoryPath() -> String? {
        UserDefaults.standard.string(forKey: Self.musicRootDirectoryKey)
    }

    func setMusicRootDirectoryPath(_ path: String) {
        UserDefaults.standard.set(path, forKey: Self.musicRootDirectoryKey)
    }
}
