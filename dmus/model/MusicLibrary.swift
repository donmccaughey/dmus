import Foundation

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
        let trackPath: String
        do {
            guard let url = Bundle.main.url(forResource: "demo-data", withExtension: "json") else {
                throw LoadDemoError.missingResource("demo-data.json")
            }
            guard let trackURL = Bundle.main.url(forResource: "demo-track", withExtension: "mp3") else {
                throw LoadDemoError.missingResource("demo-track.mp3")
            }
            let entries = try JSONDecoder().decode([DemoEntry].self, from: Data(contentsOf: url))
            guard let entry = entries.first(where: { $0.type == "directory" }) else {
                throw LoadDemoError.noDirectoryEntry
            }
            rootEntry = entry
            trackPath = trackURL.path
        } catch {
            postLoadDidFail(error)
            return MusicLibrary()
        }
        let rootPath = rootEntry.name ?? "/"
        let children = demoChildren(
            of: rootEntry,
            path: rootPath,
            trackPath: trackPath,
            folderName: nil,
            parentFolderName: nil
        )
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
        case missingResource(String)
        case noDirectoryEntry
    }

    // folderName and parentFolderName are nil for the root folder and its
    // children respectively, which is how tracks fall back to "(no album)" and
    // "(no artist)".
    private static func loadChildren(
        of directory: URL,
        folderName: String?,
        parentFolderName: String?
    ) -> [FolderChild] {
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

        var children: [FolderChild] = []
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

    // The demo data has only names, so the localized display name rule cannot
    // apply. The hidden file rule is applied by leading dot and the package
    // rule by discarding `.itlp` directories, the only package in the data.
    // Every track points at the bundled demo file so it is playable.
    private static func demoChildren(
        of entry: DemoEntry,
        path: String,
        trackPath: String,
        folderName: String?,
        parentFolderName: String?
    ) -> [FolderChild] {
        var children: [FolderChild] = []
        for child in entry.contents ?? [] {
            guard let name = child.name, !name.hasPrefix(".") else { continue }
            let childPath = path + "/" + name
            if child.type == "directory" {
                if (name as NSString).pathExtension.lowercased() == "itlp" { continue }
                let grandchildren = demoChildren(
                    of: child,
                    path: childPath,
                    trackPath: trackPath,
                    folderName: name,
                    parentFolderName: folderName
                )
                children.append(.folder(Folder(path: childPath, name: name, children: grandchildren)))
            } else if child.type == "file",
                      let track = track(
                        displayName: name,
                        pathExtension: (name as NSString).pathExtension,
                        path: trackPath,
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

    private static func sortedByName(_ nodes: [FolderChild]) -> [FolderChild] {
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
