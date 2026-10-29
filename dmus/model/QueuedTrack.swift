import Foundation

// The same track can be queued more than once, so each entry gets its own
// identity instead of borrowing the track's.
nonisolated struct QueuedTrack: Identifiable, Hashable, Sendable {
    let id: UUID
    let track: Track

    init(_ track: Track) {
        id = UUID()
        self.track = track
    }
}
