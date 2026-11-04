import Foundation
import Wrappers

public struct MusicRootDirectory: Sendable {
    public let url: URL
    public let isSecurityScoped: Bool

    public init(url: URL, isSecurityScoped: Bool) {
        self.url = url
        self.isSecurityScoped = isSecurityScoped
    }

    public static func locate(
        fileSystem: any FileSystem = FileSystemReal(),
        preferences: any Preferences = PreferencesReal()
    ) throws -> MusicRootDirectory {
        #if os(macOS)
        if let bookmark = preferences.getMusicRootDirectoryBookmark(),
           let saved = access(bookmark, fileSystem: fileSystem, preferences: preferences) {
            return saved
        }
        // The Music folder entitlement grants access without a bookmark.
        return MusicRootDirectory(url: try fileSystem.getMusicDirectoryURL(), isSecurityScoped: false)
        #else
        let applicationSupport = try fileSystem.getApplicationSupportDirectoryURL()
        let url = applicationSupport.appendingPathComponent("Music", isDirectory: true)
        try fileSystem.createDirectory(at: url)
        try fileSystem.excludeFromBackup(url)
        return MusicRootDirectory(url: url, isSecurityScoped: false)
        #endif
    }

    #if os(macOS)
    public static func choose(
        _ url: URL,
        fileSystem: any FileSystem,
        preferences: any Preferences
    ) -> MusicRootDirectory {
        // The open panel already grants access for this session, so a
        // bookmark failure only loses the choice at the next launch.
        guard let bookmark = try? fileSystem.makeSecurityScopedBookmark(for: url) else {
            return MusicRootDirectory(url: url, isSecurityScoped: false)
        }
        preferences.setMusicRootDirectoryBookmark(bookmark)
        return access(bookmark, fileSystem: fileSystem, preferences: preferences)
            ?? MusicRootDirectory(url: url, isSecurityScoped: false)
    }

    public func stopAccessing(fileSystem: any FileSystem) {
        if isSecurityScoped {
            fileSystem.stopAccessing(url)
        }
    }

    private static func access(
        _ bookmark: Data,
        fileSystem: any FileSystem,
        preferences: any Preferences
    ) -> MusicRootDirectory? {
        guard let resolved = try? fileSystem.resolveSecurityScopedBookmark(bookmark) else {
            return nil
        }
        if resolved.isStale,
           let fresh = try? fileSystem.makeSecurityScopedBookmark(for: resolved.url) {
            preferences.setMusicRootDirectoryBookmark(fresh)
        }
        guard fileSystem.startAccessing(resolved.url) else {
            return nil
        }
        return MusicRootDirectory(url: resolved.url, isSecurityScoped: true)
    }
    #endif
}
