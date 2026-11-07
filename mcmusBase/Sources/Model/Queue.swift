import Foundation

public final class Queue {
    public static let didChangeNotification = Notification.Name("QueueDidChange")

    private(set) public var queuedTracks: [QueuedTrack] = []

    public init() {}

    public var tracks: [Track] { queuedTracks.map(\.track) }

    public var isEmpty: Bool { queuedTracks.isEmpty }

    public func add(_ child: FolderChild) {
        add([child])
    }

    public func add(_ children: [FolderChild]) {
        let tracks = children.flatMap(\.trackDescendants)
        guard !tracks.isEmpty else { return }
        queuedTracks.append(contentsOf: tracks.map { QueuedTrack(track: $0) })
        postDidChange()
    }

    public func removeFirst() {
        guard !queuedTracks.isEmpty else { return }
        queuedTracks.removeFirst()
        postDidChange()
    }

    public func clear() {
        guard !queuedTracks.isEmpty else { return }
        queuedTracks.removeAll()
        postDidChange()
    }

    private func postDidChange() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
