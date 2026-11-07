import Foundation
import Wrappers

public final class PreferencesFake: Preferences, @unchecked Sendable {
    public var musicRootDirectoryBookmark: Data?

    public init(musicRootDirectoryBookmark: Data?) {
        self.musicRootDirectoryBookmark = musicRootDirectoryBookmark
    }

    public convenience init() {
        self.init(musicRootDirectoryBookmark: nil)
    }

    public func getMusicRootDirectoryBookmark() -> Data? {
        musicRootDirectoryBookmark
    }

    public func setMusicRootDirectoryBookmark(_ bookmark: Data) {
        musicRootDirectoryBookmark = bookmark
    }
}
