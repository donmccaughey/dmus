import Foundation
import Wrappers

public final class PreferencesFake: Preferences, @unchecked Sendable {
    public var musicRootDirectoryPath: String?

    public init(musicRootDirectoryPath: String? = nil) {
        self.musicRootDirectoryPath = musicRootDirectoryPath
    }

    public func getMusicRootDirectoryPath() -> String? {
        musicRootDirectoryPath
    }

    public func setMusicRootDirectoryPath(_ path: String) {
        musicRootDirectoryPath = path
    }
}
