import Foundation
import Wrappers

public final class PreferencesFake: Preferences, @unchecked Sendable {
    public var musicRootDirectoryBookmark: Data?

    public init(musicRootDirectoryBookmark: Data? = nil) {
        self.musicRootDirectoryBookmark = musicRootDirectoryBookmark
    }

    public func getMusicRootDirectoryBookmark() -> Data? {
        musicRootDirectoryBookmark
    }

    public func setMusicRootDirectoryBookmark(_ bookmark: Data) {
        musicRootDirectoryBookmark = bookmark
    }
}
