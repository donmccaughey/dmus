import Foundation

public struct PreferencesReal: Preferences {
    private static let musicRootDirectoryBookmarkKey = "musicRootDirectoryBookmark"

    public init() {}
    
    public func getMusicRootDirectoryBookmark() -> Data? {
        UserDefaults.standard.data(forKey: Self.musicRootDirectoryBookmarkKey)
    }

    public func setMusicRootDirectoryBookmark(_ bookmark: Data) {
        UserDefaults.standard.set(bookmark, forKey: Self.musicRootDirectoryBookmarkKey)
    }
}
