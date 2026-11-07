import Foundation

public struct MusicLibrary: Sendable {
    public let rootFolder: Folder

    public init() {
        rootFolder = Folder()
    }

    public init(rootFolder: Folder) {
        self.rootFolder = rootFolder
    }

    public var isEmpty: Bool {
        rootFolder.children.isEmpty
    }
}
