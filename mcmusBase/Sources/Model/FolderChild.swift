import Foundation

@objc public protocol FolderChild: NSObjectProtocol, Sendable {
    var name: String { get }
    var children: [FolderChild] { get }
    var trackDescendants: [Track] { get }
}

public extension Array where Element == FolderChild {
    func sortedByName() -> [FolderChild] {
        sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
