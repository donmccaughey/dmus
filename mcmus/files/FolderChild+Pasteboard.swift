#if os(macOS)
import AppKit
import Model

nonisolated extension NSPasteboard.PasteboardType {
    static let folderChild = NSPasteboard.PasteboardType("cc.donm.mcmus.folder-child")
}

nonisolated enum FolderChildPasteboard {
    static func pasteboardItem(for child: FolderChild) -> NSPasteboardItem {
        let item = NSPasteboardItem()
        let payload = FolderChildPayload(child: child)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: payload, requiringSecureCoding: true) {
            item.setData(data, forType: .folderChild)
        }
        return item
    }

    static func child(in item: NSPasteboardItem) -> FolderChild? {
        guard let data = item.data(forType: .folderChild),
              let payload = try? NSKeyedUnarchiver.unarchivedObject(ofClass: FolderChildPayload.self, from: data)
        else { return nil }
        return payload.child
    }

    static func children(in pasteboard: NSPasteboard) -> [FolderChild] {
        (pasteboard.pasteboardItems ?? []).compactMap(child(in:))
    }
}

// The model classes stay free of coding; drags are app-local, so this
// archive format answers to nothing else.
@objc(FolderChildPayload)
private nonisolated final class FolderChildPayload: NSObject, NSSecureCoding {
    private enum Key {
        static let kind = "kind"
        static let path = "path"
        static let name = "name"
        static let children = "children"
        static let trackName = "trackName"
        static let albumName = "albumName"
        static let artistName = "artistName"
    }

    private enum Kind {
        static let folder = "folder"
        static let track = "track"
    }

    static var supportsSecureCoding: Bool { true }

    let child: FolderChild

    init(child: FolderChild) {
        self.child = child
    }

    func encode(with coder: NSCoder) {
        if let folder = child as? Folder {
            coder.encode(Kind.folder, forKey: Key.kind)
            coder.encode(folder.path, forKey: Key.path)
            coder.encode(folder.name, forKey: Key.name)
            coder.encode(folder.children.map(FolderChildPayload.init), forKey: Key.children)
        } else if let track = child as? Track {
            coder.encode(Kind.track, forKey: Key.kind)
            coder.encode(track.trackName, forKey: Key.trackName)
            coder.encode(track.albumName, forKey: Key.albumName)
            coder.encode(track.artistName, forKey: Key.artistName)
            coder.encode(track.path, forKey: Key.path)
        }
    }

    required init?(coder: NSCoder) {
        switch coder.decodeObject(of: NSString.self, forKey: Key.kind) as String? {
        case Kind.folder:
            guard let name = coder.decodeObject(of: NSString.self, forKey: Key.name) as String?,
                  let children = coder.decodeArrayOfObjects(ofClass: FolderChildPayload.self, forKey: Key.children)
            else { return nil }
            let path = coder.decodeObject(of: NSString.self, forKey: Key.path) as String?
            child = Folder(path: path, name: name, children: children.map(\.child))
        case Kind.track:
            guard let trackName = coder.decodeObject(of: NSString.self, forKey: Key.trackName) as String?,
                  let albumName = coder.decodeObject(of: NSString.self, forKey: Key.albumName) as String?,
                  let artistName = coder.decodeObject(of: NSString.self, forKey: Key.artistName) as String?,
                  let path = coder.decodeObject(of: NSString.self, forKey: Key.path) as String?
            else { return nil }
            child = Track(trackName: trackName, albumName: albumName, artistName: artistName, path: path)
        default:
            return nil
        }
    }
}
#endif
