import Foundation

public protocol Preferences: Sendable {
    func getMusicRootDirectoryPath() -> String?
    func setMusicRootDirectoryPath(_ path: String)
}
