import Foundation

nonisolated protocol Preferences: Sendable {
    func getMusicRootDirectoryPath() -> String?
    func setMusicRootDirectoryPath(_ path: String)
}
