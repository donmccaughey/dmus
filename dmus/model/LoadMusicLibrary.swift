import Foundation

nonisolated func loadMusicLibrary(musicRootDirectory: URL) -> MusicLibrary {
    let children = loadChildren(of: musicRootDirectory, folderName: nil, parentFolderName: nil)
    let rootFolder = Folder(path: musicRootDirectory.path, name: Folder.rootName, children: children)
    let library = MusicLibrary(rootFolder: rootFolder)
    postMusicLibraryDidLoad(library)
    return library
}

// folderName and parentFolderName are nil for the root folder and its
// children respectively, which is how tracks fall back to "(no album)" and
// "(no artist)".
nonisolated private func loadChildren(
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
        postMusicLibraryLoadDidFail(error)
        return []
    }

    var children: [FolderChild] = []
    for url in contents {
        let resourceValues: URLResourceValues
        do {
            resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey, .isPackageKey, .localizedNameKey])
        } catch {
            postMusicLibraryLoadDidFail(error)
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
                  let track = Track(
                    displayName: name,
                    pathExtension: url.pathExtension,
                    path: url.path,
                    folderName: folderName,
                    parentFolderName: parentFolderName
                  ) {
            children.append(.track(track))
        }
    }
    return children.sortedByName()
}
