import Foundation

nonisolated struct FileInfo: Sendable {
    let isDirectory: Bool
    let isRegularFile: Bool
    let isPackage: Bool
    let localizedName: String?
}

nonisolated protocol FileSystem: Sendable {
    func getMusicDirectoryURL() throws -> URL
    func getApplicationSupportDirectoryURL() throws -> URL
    func createDirectory(at url: URL) throws
    func excludeFromBackup(_ url: URL) throws
    func listDirectory(_ directory: URL) throws -> [URL]
    func getFileInfo(_ url: URL) throws -> FileInfo
}
