import Foundation

public protocol Preferences: Sendable {
    func getMusicRootDirectoryBookmark() -> Data?
    func setMusicRootDirectoryBookmark(_ bookmark: Data)
}
