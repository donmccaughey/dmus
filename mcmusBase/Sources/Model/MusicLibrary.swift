import Foundation

public final class MusicLibrary: NSObject, Sendable {
    public let rootFolder: Folder

    public init(rootFolder: Folder) {
        self.rootFolder = rootFolder
    }

    public override convenience init() {
        self.init(rootFolder: Folder())
    }

    public var isEmpty: Bool {
        rootFolder.children.isEmpty
    }
}
