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

public struct ResolvedBookmark: Sendable {
    public let url: URL
    public let isStale: Bool

    public init(url: URL, isStale: Bool) {
        self.url = url
        self.isStale = isStale
    }
}

public protocol FileSystem: Sendable {
    func getMusicDirectoryURL() throws -> URL
    func getApplicationSupportDirectoryURL() throws -> URL
    func createDirectory(at url: URL) throws
    func excludeFromBackup(_ url: URL) throws
    func listDirectory(_ directory: URL) throws -> [URL]
    func getFileInfo(_ url: URL) throws -> FileInfo

    // Security-scoped bookmarks are a macOS App Sandbox feature; iOS
    // keeps its music inside the app container and needs none of this.
    #if os(macOS)
    func makeSecurityScopedBookmark(for url: URL) throws -> Data
    func resolveSecurityScopedBookmark(_ bookmark: Data) throws -> ResolvedBookmark
    func startAccessing(_ url: URL) -> Bool
    func stopAccessing(_ url: URL)
    #endif
}
