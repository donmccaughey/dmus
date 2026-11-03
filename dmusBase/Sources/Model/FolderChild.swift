import Foundation

public enum FolderChild: Hashable, Sendable, Identifiable, Codable {
    case folder(Folder)
    case track(Track)

    public var id: Self { self }

    public var name: String {
        switch self {
        case .folder(let folder): folder.name
        case .track(let track): track.trackName
        }
    }

    public var children: [FolderChild]? {
        switch self {
        case .folder(let folder): folder.children
        case .track: nil
        }
    }
}

public extension Array where Element == FolderChild {
    func sortedByName() -> [FolderChild] {
        sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
