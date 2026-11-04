#if os(macOS)
import Model

// NSOutlineView keys expansion state and drags on item identity, so the
// FolderChild values need stable reference-type stand-ins.
nonisolated final class FilesTreeNode {
    let child: FolderChild
    let children: [FilesTreeNode]

    init(_ child: FolderChild) {
        self.child = child
        children = (child.children ?? []).map(FilesTreeNode.init)
    }

    var name: String { child.name }

    var isExpandable: Bool {
        if case .folder = child { true } else { false }
    }

    var systemImage: String {
        switch child {
        case .folder: "folder"
        case .track: "music.note"
        }
    }
}
#endif
