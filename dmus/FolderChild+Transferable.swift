import CoreTransferable
import Model
import UniformTypeIdentifiers

nonisolated extension UTType {
    static let folderChild = UTType(exportedAs: "cc.donm.dmus.folder-child")
}

nonisolated extension FolderChild: @retroactive Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .folderChild)
    }
}
