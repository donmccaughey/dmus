import Foundation

public struct FileInfo: Sendable {
    public let isDirectory: Bool
    public let isRegularFile: Bool
    public let isPackage: Bool
    public let localizedName: String?
    
    public init(isDirectory: Bool, isRegularFile: Bool, isPackage: Bool, localizedName: String?) {
        self.isDirectory = isDirectory
        self.isRegularFile = isRegularFile
        self.isPackage = isPackage
        self.localizedName = localizedName
    }
}

public protocol FileSystem: Sendable {
    func getMusicDirectoryURL() throws -> URL
    func getApplicationSupportDirectoryURL() throws -> URL
    func createDirectory(at url: URL) throws
    func excludeFromBackup(_ url: URL) throws
    func listDirectory(_ directory: URL) throws -> [URL]
    func getFileInfo(_ url: URL) throws -> FileInfo
}
