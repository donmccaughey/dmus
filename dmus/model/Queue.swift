import Foundation
import Observation

@Observable
final class Queue {
    private(set) var queuedTracks: [QueuedTrack] = [] {
        didSet { onChange?() }
    }

    // Views give the queue its add commands directly, so the owning player
    // listens here to keep the audio wrapper's next track current.
    @ObservationIgnored var onChange: (() -> Void)?

    var tracks: [Track] { queuedTracks.map(\.track) }

    var isEmpty: Bool { queuedTracks.isEmpty }

    func add(_ track: Track) {
        queuedTracks.append(QueuedTrack(track))
    }

    func add(_ folder: Folder) {
        queuedTracks.append(contentsOf: folder.trackDescendants.map { QueuedTrack($0) })
    }

    func add(_ child: FolderChild) {
        switch child {
        case .folder(let folder): add(folder)
        case .track(let track): add(track)
        }
    }

    func add(_ children: [FolderChild]) {
        for child in children {
            add(child)
        }
    }

    func removeFirst() {
        guard !queuedTracks.isEmpty else { return }
        queuedTracks.removeFirst()
    }

    func clear() {
        queuedTracks.removeAll()
    }
}
