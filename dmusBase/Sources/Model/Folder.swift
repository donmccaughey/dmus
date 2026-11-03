import Foundation

public struct Folder: Hashable, Sendable, Codable {
    public let path: String?
    public let name: String
    public let children: [FolderChild]

    public init() {
        path = nil
        name = Folder.rootName
        children = []
    }

    public init(path: String?, name: String, children: [FolderChild]) {
        self.path = path
        self.name = name
        self.children = children
    }

    public static let rootName = "Files"
    
    public var trackDescendants: [Track] {
        children.flatMap { child in
            switch child {
            case .folder(let folder): folder.trackDescendants
            case .track(let track): [track]
            }
        }
    }
}
