import Foundation

nonisolated struct Folder: Hashable, Sendable {
    let path: String?
    let name: String
    let children: [FolderChild]

    init() {
        path = nil
        name = Folder.rootName
        children = []
    }

    init(path: String?, name: String, children: [FolderChild]) {
        self.path = path
        self.name = name
        self.children = children
    }

    static let rootName = "Files"
}
