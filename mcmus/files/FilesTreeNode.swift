#if os(macOS)

// NSOutlineView keys expansion state and drags on item identity, but Folder
// and Track compare by value, so the tree gets identity-only stand-ins.
nonisolated final class FilesTreeNode {
    let child: FolderChild
    let children: [FilesTreeNode]

    init(_ child: FolderChild) {
        self.child = child
        children = child.children.map(FilesTreeNode.init)
    }

    var name: String { child.name }

    var isExpandable: Bool { child is Folder }

    var systemImage: String {
        child is Folder ? "folder" : "music.note"
    }
}
#endif
