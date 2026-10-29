import Foundation

nonisolated protocol Preferences: Sendable {
    func getMusicRootDirectoryPath() -> String?
    func setMusicRootDirectoryPath(_ path: String)
}

nonisolated struct RealPreferences: Preferences {
    private static let musicRootDirectoryKey = "musicRootDirectory"

    func getMusicRootDirectoryPath() -> String? {
        UserDefaults.standard.string(forKey: Self.musicRootDirectoryKey)
    }

    func setMusicRootDirectoryPath(_ path: String) {
        UserDefaults.standard.set(path, forKey: Self.musicRootDirectoryKey)
    }
}
