import Foundation

public struct PreferencesReal: Preferences {
    private static let musicRootDirectoryKey = "musicRootDirectory"

    public init() {}
    
    public func getMusicRootDirectoryPath() -> String? {
        UserDefaults.standard.string(forKey: Self.musicRootDirectoryKey)
    }

    public func setMusicRootDirectoryPath(_ path: String) {
        UserDefaults.standard.set(path, forKey: Self.musicRootDirectoryKey)
    }
}
