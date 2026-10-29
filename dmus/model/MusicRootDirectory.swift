import Foundation

nonisolated enum MusicRootDirectory {
    static func locate(
        fileSystem: any FileSystem = RealFileSystem(),
        preferences: any Preferences = RealPreferences()
    ) throws -> URL {
        #if os(macOS)
        let musicRootDirectory: URL
        if let path = preferences.getMusicRootDirectoryPath() {
            musicRootDirectory = URL(filePath: path, directoryHint: .isDirectory)
        } else {
            musicRootDirectory = try fileSystem.getMusicDirectoryURL()
            preferences.setMusicRootDirectoryPath(musicRootDirectory.path)
        }
        // Recreates the directory if the user removed it since it was saved.
        try fileSystem.createDirectory(at: musicRootDirectory)
        return musicRootDirectory
        #else
        let applicationSupport = try fileSystem.getApplicationSupportDirectoryURL()
        let musicRootDirectory = applicationSupport.appendingPathComponent("Music", isDirectory: true)
        try fileSystem.createDirectory(at: musicRootDirectory)
        try fileSystem.excludeFromBackup(musicRootDirectory)
        return musicRootDirectory
        #endif
    }
}
