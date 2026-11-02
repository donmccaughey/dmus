import Foundation
import Wrappers

public  struct FileSystemFakeError: Error, Equatable {
    let path: String
    
    public init(path: String) {
        self.path = path
    }
}

public struct FileSystemFake: FileSystem {
    public enum Kind : Sendable{
        case directory
        case file
        case package
        // Neither a directory nor a regular file, such as a symlink or socket.
        case other
    }

    public struct Entry : Sendable{
        let path: String
        let kind: Kind
        let localizedName: String?
    }

    public var entries: [Entry] = []
    public var unlistableDirectories: Set<String> = []
    public var unreadableEntries: Set<String> = []
    public var uncreatableDirectories: Set<String> = []
    public var musicDirectoryURL: URL?

    public init(
        entries: [Entry] = [],
        unlistableDirectories: Set<String> = [],
        unreadableEntries: Set<String> = [],
        uncreatableDirectories: Set<String> = [],
        musicDirectoryURL: URL? = nil
    ) {
        self.entries = entries
        self.unlistableDirectories = unlistableDirectories
        self.unreadableEntries = unreadableEntries
        self.uncreatableDirectories = uncreatableDirectories
        self.musicDirectoryURL = musicDirectoryURL
    }
    
    public mutating func add(_ path: String, _ kind: Kind = .file, localizedName: String? = nil) {
        entries.append(Entry(path: path, kind: kind, localizedName: localizedName))
    }

    public func getMusicDirectoryURL() throws -> URL {
        guard let musicDirectoryURL else {
            throw FileSystemFakeError(path: "getMusicDirectoryURL")
        }
        return musicDirectoryURL
    }

    public func getApplicationSupportDirectoryURL() throws -> URL {
        throw FileSystemFakeError(path: "getApplicationSupportDirectoryURL")
    }

    public func createDirectory(at url: URL) throws {
        if uncreatableDirectories.contains(url.path) {
            throw FileSystemFakeError(path: url.path)
        }
    }

    public func excludeFromBackup(_ url: URL) throws {
        throw FileSystemFakeError(path: url.path)
    }

    // Entries come back in insertion order so tests can see the loader sort.
    public func listDirectory(_ directory: URL) throws -> [URL] {
        if unlistableDirectories.contains(directory.path) {
            throw FileSystemFakeError(path: directory.path)
        }
        return entries
            .filter { ($0.path as NSString).deletingLastPathComponent == directory.path }
            .map { entry in
                let hint: URL.DirectoryHint = switch entry.kind {
                case .directory, .package: .isDirectory
                case .file, .other: .notDirectory
                }
                return URL(filePath: entry.path, directoryHint: hint)
            }
    }

    public func getFileInfo(_ url: URL) throws -> FileInfo {
        guard !unreadableEntries.contains(url.path),
              let entry = entries.first(where: { $0.path == url.path })
        else { throw FileSystemFakeError(path: url.path) }
        return FileInfo(
            isDirectory: entry.kind == .directory || entry.kind == .package,
            isRegularFile: entry.kind == .file,
            isPackage: entry.kind == .package,
            localizedName: entry.localizedName
        )
    }
}
