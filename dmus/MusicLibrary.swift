import Foundation

nonisolated struct Track: Hashable, Sendable {
    let trackName: String
    let albumName: String
    let artistName: String
    let path: String
}

nonisolated struct Folder: Hashable, Sendable {
    let path: String?
    let name: String
    let children: [LibraryNode]

    init() {
        path = nil
        name = Folder.rootName
        children = []
    }

    init(path: String?, name: String, children: [LibraryNode]) {
        self.path = path
        self.name = name
        self.children = children
    }

    static let rootName = "Music Library"
}

nonisolated enum LibraryNode: Hashable, Sendable, Identifiable {
    case folder(Folder)
    case track(Track)

    // The root folder is never a node, so every node has a non-nil path.
    var id: String {
        switch self {
        case .folder(let folder): folder.path ?? ""
        case .track(let track): track.path
        }
    }

    var name: String {
        switch self {
        case .folder(let folder): folder.name
        case .track(let track): track.trackName
        }
    }

    var children: [LibraryNode]? {
        switch self {
        case .folder(let folder): folder.children
        case .track: nil
        }
    }
}

nonisolated extension Notification.Name {
    static let musicLibraryDidLoad = Notification.Name("cc.donm.dmus.musicLibraryDidLoad")
    static let musicLibraryLoadDidFail = Notification.Name("cc.donm.dmus.musicLibraryLoadDidFail")
}

nonisolated struct MusicLibrary: Sendable {
    let rootFolder: Folder

    init() {
        rootFolder = Folder()
    }

    init(rootFolder: Folder) {
        self.rootFolder = rootFolder
    }

    var isEmpty: Bool {
        rootFolder.children.isEmpty
    }

    static func load(musicRootDirectory: URL) -> MusicLibrary {
        let children = loadChildren(of: musicRootDirectory, folderName: nil, parentFolderName: nil)
        let rootFolder = Folder(path: musicRootDirectory.path, name: Folder.rootName, children: children)
        let library = MusicLibrary(rootFolder: rootFolder)
        postOnMain(.musicLibraryDidLoad, object: library)
        return library
    }

    static func loadDemo() -> MusicLibrary {
        let rootEntry: DemoEntry
        do {
            guard let url = Bundle.main.url(forResource: "demo-data", withExtension: "json") else {
                throw LoadDemoError.missingResource
            }
            let entries = try JSONDecoder().decode([DemoEntry].self, from: Data(contentsOf: url))
            guard let entry = entries.first(where: { $0.type == "directory" }) else {
                throw LoadDemoError.noDirectoryEntry
            }
            rootEntry = entry
        } catch {
            postLoadDidFail(error)
            return MusicLibrary()
        }
        let rootPath = rootEntry.name ?? "/"
        let children = demoChildren(of: rootEntry, path: rootPath, folderName: nil, parentFolderName: nil)
        let rootFolder = Folder(path: rootPath, name: Folder.rootName, children: children)
        let library = MusicLibrary(rootFolder: rootFolder)
        postOnMain(.musicLibraryDidLoad, object: library)
        return library
    }

    static func postLoadDidFail(_ error: any Error) {
        postOnMain(.musicLibraryLoadDidFail, object: error)
    }

    private static let musicFileExtensions: Set<String> = ["mp3", "m4a"]

    private struct DemoEntry: Decodable {
        let type: String
        let name: String?
        let contents: [DemoEntry]?
    }

    private enum LoadDemoError: Error {
        case missingResource
        case noDirectoryEntry
    }

    // folderName and parentFolderName are nil for the root folder and its
    // children respectively, which is how tracks fall back to "(no album)" and
    // "(no artist)".
    private static func loadChildren(
        of directory: URL,
        folderName: String?,
        parentFolderName: String?
    ) -> [LibraryNode] {
        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isPackageKey, .localizedNameKey],
                options: .skipsHiddenFiles
            )
        } catch {
            postLoadDidFail(error)
            return []
        }

        var children: [LibraryNode] = []
        for url in contents {
            let resourceValues: URLResourceValues
            do {
                resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey, .isPackageKey, .localizedNameKey])
            } catch {
                postLoadDidFail(error)
                continue
            }
            // Packages such as Apple Music's `Music Library.musiclibrary` are
            // directories on disk but not music directories.
            if resourceValues.isPackage == true { continue }
            let name = resourceValues.localizedName ?? url.lastPathComponent
            if resourceValues.isDirectory == true {
                let grandchildren = loadChildren(of: url, folderName: name, parentFolderName: folderName)
                children.append(.folder(Folder(path: url.path, name: name, children: grandchildren)))
            } else if resourceValues.isRegularFile == true,
                      let track = track(
                        displayName: name,
                        pathExtension: url.pathExtension,
                        path: url.path,
                        folderName: folderName,
                        parentFolderName: parentFolderName
                      ) {
                children.append(.track(track))
            }
        }
        return sortedByName(children)
    }

    // The demo data has only names, so the localized display name and package
    // rules cannot apply; the hidden file rule is applied by leading dot.
    private static func demoChildren(
        of entry: DemoEntry,
        path: String,
        folderName: String?,
        parentFolderName: String?
    ) -> [LibraryNode] {
        var children: [LibraryNode] = []
        for child in entry.contents ?? [] {
            guard let name = child.name, !name.hasPrefix(".") else { continue }
            let childPath = path + "/" + name
            if child.type == "directory" {
                let grandchildren = demoChildren(of: child, path: childPath, folderName: name, parentFolderName: folderName)
                children.append(.folder(Folder(path: childPath, name: name, children: grandchildren)))
            } else if child.type == "file",
                      let track = track(
                        displayName: name,
                        pathExtension: (name as NSString).pathExtension,
                        path: childPath,
                        folderName: folderName,
                        parentFolderName: parentFolderName
                      ) {
                children.append(.track(track))
            }
        }
        return sortedByName(children)
    }

    private static func track(
        displayName: String,
        pathExtension: String,
        path: String,
        folderName: String?,
        parentFolderName: String?
    ) -> Track? {
        guard musicFileExtensions.contains(pathExtension.lowercased()) else { return nil }
        return Track(
            trackName: trackName(displayName: displayName, pathExtension: pathExtension),
            albumName: folderName ?? Track.noAlbum,
            artistName: parentFolderName ?? Track.noArtist,
            path: path
        )
    }

    private static func sortedByName(_ nodes: [LibraryNode]) -> [LibraryNode] {
        nodes.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    // The display name already omits the extension when the Finder hides it,
    // so only strip an extension that is still present.
    private static func trackName(displayName: String, pathExtension: String) -> String {
        let suffix = "." + pathExtension
        guard !pathExtension.isEmpty,
              displayName.lowercased().hasSuffix(suffix.lowercased())
        else { return displayName }
        return String(displayName.dropLast(suffix.count))
    }

    private static func postOnMain(_ name: Notification.Name, object: (any Sendable)?) {
        Task { @MainActor in
            NotificationCenter.default.post(name: name, object: object)
        }
    }
}

nonisolated extension Track {
    static let noAlbum = "(no album)"
    static let noArtist = "(no artist)"
}
