import Foundation

public final class Folder: NSObject, FolderChild, Sendable {
    public let path: String?
    public let name: String
    public let children: [FolderChild]

    public static let rootName = "Files"

    public init(path: String?, name: String, children: [FolderChild]) {
        self.path = path
        self.name = name
        self.children = children
    }

    public override convenience init() {
        self.init(path: nil, name: Folder.rootName, children: [])
    }

    public var trackDescendants: [Track] {
        children.flatMap(\.trackDescendants)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Folder else { return false }
        if other === self { return true }
        return path == other.path
            && name == other.name
            && children.count == other.children.count
            && zip(children, other.children).allSatisfy { $0.isEqual($1) }
    }

    // Shallow, so hashing a tree does not walk it; isEqual still does.
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(path)
        hasher.combine(name)
        hasher.combine(children.count)
        return hasher.finalize()
    }

    public override var description: String {
        "Folder(\(path ?? "nil"), \(name), \(children.count) children)"
    }
}
