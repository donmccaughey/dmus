import CoreTransferable
import UniformTypeIdentifiers

nonisolated extension UTType {
    static let folderChild = UTType(exportedAs: "cc.donm.dmus.folder-child")
}

nonisolated extension FolderChild: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .folderChild)
    }
}
