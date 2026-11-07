import Foundation
import Observation

@Observable
public final class Queue {
    private(set) public var queuedTracks: [QueuedTrack] = [] {
        didSet { onChange?() }
    }

    // Views give the queue its add commands directly, so the owning player
    // listens here to keep the audio wrapper's next track current.
    @ObservationIgnored public var onChange: (() -> Void)?

    public init() {}
    
    public var tracks: [Track] { queuedTracks.map(\.track) }

    public var isEmpty: Bool { queuedTracks.isEmpty }

    public func add(_ track: Track) {
        queuedTracks.append(QueuedTrack(track: track))
    }

    public func add(_ folder: Folder) {
        queuedTracks.append(contentsOf: folder.trackDescendants.map { QueuedTrack(track: $0) })
    }

    public func add(_ child: FolderChild) {
        switch child {
        case .folder(let folder): add(folder)
        case .track(let track): add(track)
        }
    }

    public func add(_ children: [FolderChild]) {
        for child in children {
            add(child)
        }
    }

    public func removeFirst() {
        guard !queuedTracks.isEmpty else { return }
        queuedTracks.removeFirst()
    }

    public func clear() {
        queuedTracks.removeAll()
    }
}
