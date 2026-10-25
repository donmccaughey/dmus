import Foundation

nonisolated enum MusicRootDirectory {
    static func locate() throws -> URL {
        let fileManager = FileManager.default
        #if os(macOS)
        return try fileManager.url(
            for: .musicDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        #else
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        var musicRootDirectory = applicationSupport.appendingPathComponent("Music", isDirectory: true)
        try fileManager.createDirectory(at: musicRootDirectory, withIntermediateDirectories: true)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try musicRootDirectory.setResourceValues(resourceValues)
        return musicRootDirectory
        #endif
    }
}
