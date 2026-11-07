#if os(macOS)
import AppKit
import DeveloperToolsSupport
import Model

final class FilesTreeView: NSScrollView {
    private let outlineView = NSOutlineView()
    private let dataSource = FilesTreeDataSource()

    init() {
        super.init(frame: .zero)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        outlineView.style = .inset
        outlineView.usesAlternatingRowBackgroundColors = false
        outlineView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        outlineView.setDraggingSourceOperationMask(.copy, forLocal: true)
        outlineView.dataSource = dataSource
        outlineView.delegate = dataSource
        documentView = outlineView
        hasVerticalScroller = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setLibrary(_ library: MusicLibrary) {
        dataSource.nodes = library.rootFolder.children.map(FilesTreeNode.init)
        outlineView.reloadData()
    }
}

private final class FilesTreeDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    private static let cellIdentifier = NSUserInterfaceItemIdentifier("FilesTreeCell")

    var nodes: [FilesTreeNode] = []

    private func children(of item: Any?) -> [FilesTreeNode] {
        (item as? FilesTreeNode)?.children ?? nodes
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        children(of: item).count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        children(of: item)[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? FilesTreeNode)?.isExpandable ?? false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? FilesTreeNode else { return nil }
        let cell = outlineView.makeView(withIdentifier: Self.cellIdentifier, owner: nil) as? NSTableCellView
            ?? Self.makeCell()
        cell.imageView?.image = NSImage(systemSymbolName: node.systemImage, accessibilityDescription: nil)
        cell.textField?.stringValue = node.name
        return cell
    }

    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        (item as? FilesTreeNode)?.child.pasteboardItem()
    }

    private static func makeCell() -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = cellIdentifier

        let imageView = NSImageView()
        imageView.contentTintColor = .controlAccentColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(imageView)
        cell.imageView = imageView

        let textField = NSTextField(labelWithString: "")
        textField.lineBreakMode = .byTruncatingTail
        textField.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(textField)
        cell.textField = textField

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
            textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }
}

#Preview {
    let treeView = FilesTreeView()
    treeView.setLibrary(MusicLibrary(rootFolder: Folder(
        path: "/Music",
        name: Folder.rootName,
        children: [
            .folder(Folder(path: "/Music/Artist", name: "Artist", children: [
                .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
                    .track(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3")),
                ])),
            ])),
            .track(Track(trackName: "Loose", albumName: "(no album)", artistName: "(no artist)", path: "/Music/Loose.m4a")),
        ]
    )))
    treeView.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
    return treeView
}
#endif
