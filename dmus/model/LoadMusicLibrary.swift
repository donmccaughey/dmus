import Foundation

nonisolated func loadMusicLibrary(
    musicRootDirectory: URL,
    fileSystem: any FileSystem = RealFileSystem()
) -> MusicLibrary {
    let children = loadChildren(
        of: musicRootDirectory,
        folderName: nil,
        parentFolderName: nil,
        fileSystem: fileSystem
    )
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
    parentFolderName: String?,
    fileSystem: any FileSystem
) -> [FolderChild] {
    let contents: [URL]
    do {
        contents = try fileSystem.listDirectory(directory)
    } catch {
        postMusicLibraryLoadDidFail(error)
        return []
    }

    var children: [FolderChild] = []
    for url in contents {
        let info: FileInfo
        do {
            info = try fileSystem.getFileInfo(url)
        } catch {
            postMusicLibraryLoadDidFail(error)
            continue
        }
        // Packages such as Apple Music's `Music Library.musiclibrary` are
        // directories on disk but not music directories.
        if info.isPackage { continue }
        let name = info.localizedName ?? url.lastPathComponent
        if info.isDirectory {
            let grandchildren = loadChildren(
                of: url,
                folderName: name,
                parentFolderName: folderName,
                fileSystem: fileSystem
            )
            children.append(.folder(Folder(path: url.path, name: name, children: grandchildren)))
        } else if info.isRegularFile,
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
