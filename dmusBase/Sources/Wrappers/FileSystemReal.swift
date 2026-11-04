import Foundation

public struct FileSystemReal: FileSystem {
    // Prefetched by listDirectory so getFileInfo reads from the URL's cache
    // instead of going back to disk for each entry.
    private static let fileInfoKeys: Set<URLResourceKey> = [
        .isDirectoryKey, .isRegularFileKey, .isPackageKey, .localizedNameKey
    ]

    public init() {}
    
    public func getMusicDirectoryURL() throws -> URL {
        let url = try FileManager.default.url(
            for: .musicDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        // Inside the App Sandbox the home directory is the app container, whose
        // Music entry is a symlink to the real ~/Music; resolve it so the user
        // sees the real path.
        return url.resolvingSymlinksInPath()
    }

    public func getApplicationSupportDirectoryURL() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    public func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    public func excludeFromBackup(_ url: URL) throws {
        var url = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    public func listDirectory(_ directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(Self.fileInfoKeys),
            options: .skipsHiddenFiles
        )
    }

    public func getFileInfo(_ url: URL) throws -> FileInfo {
        let values = try url.resourceValues(forKeys: Self.fileInfoKeys)
        return FileInfo(
            isDirectory: values.isDirectory == true,
            isRegularFile: values.isRegularFile == true,
            isPackage: values.isPackage == true,
            localizedName: values.localizedName
        )
    }

    #if os(macOS)
    public func makeSecurityScopedBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    public func resolveSecurityScopedBookmark(_ bookmark: Data) throws -> ResolvedBookmark {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return ResolvedBookmark(url: url, isStale: isStale)
    }

    public func startAccessing(_ url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    public func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
    #endif
}
