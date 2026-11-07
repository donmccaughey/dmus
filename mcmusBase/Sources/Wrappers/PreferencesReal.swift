import Foundation

public final class PreferencesReal: NSObject, Preferences {
    private static let musicRootDirectoryBookmarkKey = "musicRootDirectoryBookmark"

    public func getMusicRootDirectoryBookmark() -> Data? {
        UserDefaults.standard.data(forKey: Self.musicRootDirectoryBookmarkKey)
    }

    public func setMusicRootDirectoryBookmark(_ bookmark: Data) {
        UserDefaults.standard.set(bookmark, forKey: Self.musicRootDirectoryBookmarkKey)
    }
}
