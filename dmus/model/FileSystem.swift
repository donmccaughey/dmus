import Foundation

nonisolated protocol FileSystem: Sendable {
    func getMusicDirectoryURL() throws -> URL
    func getApplicationSupportDirectoryURL() throws -> URL
    func createDirectory(at url: URL) throws
    func excludeFromBackup(_ url: URL) throws
}

nonisolated struct RealFileSystem: FileSystem {
    func getMusicDirectoryURL() throws -> URL {
        try FileManager.default.url(
            for: .musicDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    func getApplicationSupportDirectoryURL() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func excludeFromBackup(_ url: URL) throws {
        var url = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }
}
