#if os(macOS)
import AppKit
import Model

nonisolated extension NSPasteboard.PasteboardType {
    static let folderChild = NSPasteboard.PasteboardType("cc.donm.dmus.folder-child")
}

nonisolated extension FolderChild {
    func pasteboardItem() -> NSPasteboardItem {
        let item = NSPasteboardItem()
        if let data = try? JSONEncoder().encode(self) {
            item.setData(data, forType: .folderChild)
        }
        return item
    }

    init?(pasteboardItem: NSPasteboardItem) {
        guard let data = pasteboardItem.data(forType: .folderChild),
              let child = try? JSONDecoder().decode(FolderChild.self, from: data)
        else { return nil }
        self = child
    }

    static func folderChildren(in pasteboard: NSPasteboard) -> [FolderChild] {
        (pasteboard.pasteboardItems ?? []).compactMap(FolderChild.init(pasteboardItem:))
    }
}
#endif
