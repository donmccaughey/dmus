import Foundation

nonisolated struct Folder: Hashable, Sendable, Codable {
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

nonisolated extension Folder {
    var trackDescendants: [Track] {
        children.flatMap { child in
            switch child {
            case .folder(let folder): folder.trackDescendants
            case .track(let track): [track]
            }
        }
    }
}
