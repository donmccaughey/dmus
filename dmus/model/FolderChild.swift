import Foundation

nonisolated enum FolderChild: Hashable, Sendable, Identifiable, Codable {
    case folder(Folder)
    case track(Track)

    var id: Self { self }

    var name: String {
        switch self {
        case .folder(let folder): folder.name
        case .track(let track): track.trackName
        }
    }

    var children: [FolderChild]? {
        switch self {
        case .folder(let folder): folder.children
        case .track: nil
        }
    }
}

nonisolated extension Array where Element == FolderChild {
    func sortedByName() -> [FolderChild] {
        sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
