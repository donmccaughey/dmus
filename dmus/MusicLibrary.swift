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

    static func load(musicDirectory: URL) -> MusicLibrary {
        let children = loadChildren(of: musicDirectory, folderName: nil, parentFolderName: nil)
        let rootFolder = Folder(path: musicDirectory.path, name: Folder.rootName, children: children)
        let library = MusicLibrary(rootFolder: rootFolder)
        postOnMain(.musicLibraryDidLoad, object: library)
        return library
    }

    static func postLoadDidFail(_ error: any Error) {
        postOnMain(.musicLibraryLoadDidFail, object: error)
    }

    private static let musicFileExtensions: Set<String> = ["mp3", "m4a"]

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
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isPackageKey],
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
                resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey, .isPackageKey])
            } catch {
                postLoadDidFail(error)
                continue
            }
            // Packages such as Apple Music's `Music Library.musiclibrary` are
            // directories on disk but not music folders.
            if resourceValues.isPackage == true { continue }
            let name = url.lastPathComponent
            if resourceValues.isDirectory == true {
                let grandchildren = loadChildren(of: url, folderName: name, parentFolderName: folderName)
                children.append(.folder(Folder(path: url.path, name: name, children: grandchildren)))
            } else if resourceValues.isRegularFile == true,
                      musicFileExtensions.contains(url.pathExtension.lowercased()) {
                let track = Track(
                    trackName: url.deletingPathExtension().lastPathComponent,
                    albumName: folderName ?? Track.noAlbum,
                    artistName: parentFolderName ?? Track.noArtist,
                    path: url.path
                )
                children.append(.track(track))
            }
        }
        return children.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
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
