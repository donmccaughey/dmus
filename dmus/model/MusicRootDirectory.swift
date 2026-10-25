import Foundation

nonisolated enum MusicRootDirectory {
    static func locate(fileSystem: any FileSystem = RealFileSystem()) throws -> URL {
        #if os(macOS)
        return try fileSystem.getMusicDirectoryURL()
        #else
        let applicationSupport = try fileSystem.getApplicationSupportDirectoryURL()
        let musicRootDirectory = applicationSupport.appendingPathComponent("Music", isDirectory: true)
        try fileSystem.createDirectory(at: musicRootDirectory)
        try fileSystem.excludeFromBackup(musicRootDirectory)
        return musicRootDirectory
        #endif
    }
}
