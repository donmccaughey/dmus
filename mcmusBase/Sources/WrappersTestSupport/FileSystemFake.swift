import Foundation
import Wrappers

public let FileSystemFakeErrorDomain = "FileSystemFakeErrorDomain"

public enum FileSystemFakeErrorCode: Int {
    case operationFailed = 1
}

public struct FileSystemFakeError: CustomNSError {
    public static let errorDomain = FileSystemFakeErrorDomain

    let path: String

    public init(path: String) {
        self.path = path
    }

    public var errorCode: Int { FileSystemFakeErrorCode.operationFailed.rawValue }

    public var errorUserInfo: [String: Any] { [NSFilePathErrorKey: path] }
}

public enum FileSystemFakeKind: Sendable {
    case directory
    case file
    case package
    // Neither a directory nor a regular file, such as a symlink or socket.
    case other
}

public final class FileSystemFakeEntry: NSObject, Sendable {
    public let path: String
    public let kind: FileSystemFakeKind
    public let localizedName: String?

    public init(path: String, kind: FileSystemFakeKind, localizedName: String?) {
        self.path = path
        self.kind = kind
        self.localizedName = localizedName
    }
}

public final class FileSystemFake: FileSystem, @unchecked Sendable {
    public var entries: [FileSystemFakeEntry] = []
    public var unlistableDirectories: Set<String> = []
    public var unreadableEntries: Set<String> = []
    public var uncreatableDirectories: Set<String> = []
    public var unbookmarkablePaths: Set<String> = []
    public var unresolvableBookmarks: Set<String> = []
    public var staleBookmarks: Set<String> = []
    public var inaccessiblePaths: Set<String> = []
    public var musicDirectoryURL: URL?
    private(set) public var bookmarked: [String] = []
    private(set) public var started: [String] = []
    private(set) public var stopped: [String] = []

    public init() {}

    public func addPath(_ path: String) {
        addPath(path, kind: .file, localizedName: nil)
    }

    public func addPath(_ path: String, kind: FileSystemFakeKind) {
        addPath(path, kind: kind, localizedName: nil)
    }

    public func addPath(_ path: String, kind: FileSystemFakeKind, localizedName: String?) {
        entries.append(FileSystemFakeEntry(path: path, kind: kind, localizedName: localizedName))
    }

    public static func bookmark(forPath path: String) -> Data {
        Data(path.utf8)
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

    public func getFileInfo(_ url: URL) throws -> FileSystemItemInfo {
        guard !unreadableEntries.contains(url.path),
              let entry = entries.first(where: { $0.path == url.path })
        else { throw FileSystemFakeError(path: url.path) }
        return FileSystemItemInfo(
            isDirectory: entry.kind == .directory || entry.kind == .package,
            isRegularFile: entry.kind == .file,
            isPackage: entry.kind == .package,
            localizedName: entry.localizedName
        )
    }

    #if os(macOS)
    public func makeSecurityScopedBookmark(for url: URL) throws -> Data {
        if unbookmarkablePaths.contains(url.path) {
            throw FileSystemFakeError(path: url.path)
        }
        bookmarked.append(url.path)
        return Self.bookmark(forPath: url.path)
    }

    public func resolveSecurityScopedBookmark(_ bookmark: Data) throws -> ResolvedBookmark {
        let path = String(decoding: bookmark, as: UTF8.self)
        if unresolvableBookmarks.contains(path) {
            throw FileSystemFakeError(path: path)
        }
        return ResolvedBookmark(
            url: URL(filePath: path, directoryHint: .isDirectory),
            isStale: staleBookmarks.contains(path)
        )
    }

    public func startAccessing(_ url: URL) -> Bool {
        if inaccessiblePaths.contains(url.path) {
            return false
        }
        started.append(url.path)
        return true
    }

    public func stopAccessing(_ url: URL) {
        stopped.append(url.path)
    }
    #endif
}
