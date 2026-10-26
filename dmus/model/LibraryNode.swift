import Foundation

nonisolated enum LibraryNode: Hashable, Sendable, Identifiable {
    case folder(Folder)
    case track(Track)

    var id: Self { self }

    var name: String {
        switch self {
        case .folder(let folder): folder.name
        case .track(let track): track.trackName
        }
    }

    var children: [LibraryNode]? {
        switch self {
        case .folder(let folder): folder.children
        case .track: nil
        }
    }
}
