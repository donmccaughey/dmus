import Foundation

nonisolated struct FakeFileSystemError: Error, Equatable {
    let path: String
}

nonisolated struct FakeFileSystem: FileSystem {
    enum Kind {
        case directory
        case file
        case package
        // Neither a directory nor a regular file, such as a symlink or socket.
        case other
    }

    struct Entry {
        let path: String
        let kind: Kind
        let localizedName: String?
    }

    var entries: [Entry] = []
    var unlistableDirectories: Set<String> = []
    var unreadableEntries: Set<String> = []
    var uncreatableDirectories: Set<String> = []
    var musicDirectoryURL: URL?

    mutating func add(_ path: String, _ kind: Kind = .file, localizedName: String? = nil) {
        entries.append(Entry(path: path, kind: kind, localizedName: localizedName))
    }

    func getMusicDirectoryURL() throws -> URL {
        guard let musicDirectoryURL else {
            throw FakeFileSystemError(path: "getMusicDirectoryURL")
        }
        return musicDirectoryURL
    }

    func getApplicationSupportDirectoryURL() throws -> URL {
        throw FakeFileSystemError(path: "getApplicationSupportDirectoryURL")
    }

    func createDirectory(at url: URL) throws {
        if uncreatableDirectories.contains(url.path) {
            throw FakeFileSystemError(path: url.path)
        }
    }

    func excludeFromBackup(_ url: URL) throws {
        throw FakeFileSystemError(path: url.path)
    }

    // Entries come back in insertion order so tests can see the loader sort.
    func listDirectory(_ directory: URL) throws -> [URL] {
        if unlistableDirectories.contains(directory.path) {
            throw FakeFileSystemError(path: directory.path)
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

    func getFileInfo(_ url: URL) throws -> FileInfo {
        guard !unreadableEntries.contains(url.path),
              let entry = entries.first(where: { $0.path == url.path })
        else { throw FakeFileSystemError(path: url.path) }
        return FileInfo(
            isDirectory: entry.kind == .directory || entry.kind == .package,
            isRegularFile: entry.kind == .file,
            isPackage: entry.kind == .package,
            localizedName: entry.localizedName
        )
    }
}
