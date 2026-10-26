import Foundation

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
}
