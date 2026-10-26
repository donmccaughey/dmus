import Foundation

nonisolated func loadDemoMusicLibrary() -> MusicLibrary {
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
        postMusicLibraryLoadDidFail(error)
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
    postMusicLibraryDidLoad(library)
    return library
}

private struct DemoEntry: Decodable {
    let type: String
    let name: String?
    let contents: [DemoEntry]?
}

private enum LoadDemoError: Error {
    case missingResource(String)
    case noDirectoryEntry
}

// The demo data has only names, so the localized display name rule cannot
// apply. The hidden file rule is applied by leading dot and the package
// rule by discarding `.itlp` directories, the only package in the data.
// Every track points at the bundled demo file so it is playable.
nonisolated private func demoChildren(
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
                  let track = Track(
                    displayName: name,
                    pathExtension: (name as NSString).pathExtension,
                    path: trackPath,
                    folderName: folderName,
                    parentFolderName: parentFolderName
                  ) {
            children.append(.track(track))
        }
    }
    return children.sortedByName()
}
