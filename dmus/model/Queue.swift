import Foundation
import Observation

@Observable
final class Queue {
    private(set) var queuedTracks: [QueuedTrack] = []

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
}
