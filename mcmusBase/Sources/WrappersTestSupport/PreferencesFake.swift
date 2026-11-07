import Foundation
import Wrappers

public final class PreferencesFake: NSObject, Preferences, @unchecked Sendable {
    public var musicRootDirectoryBookmark: Data?

    public init(musicRootDirectoryBookmark: Data?) {
        self.musicRootDirectoryBookmark = musicRootDirectoryBookmark
        super.init()
    }

    public override convenience init() {
        self.init(musicRootDirectoryBookmark: nil)
    }

    public func getMusicRootDirectoryBookmark() -> Data? {
        musicRootDirectoryBookmark
    }

    public func setMusicRootDirectoryBookmark(_ bookmark: Data) {
        musicRootDirectoryBookmark = bookmark
    }
}
