import Foundation

// The same track can be queued more than once, so each entry gets its own
// identity instead of borrowing the track's.
public struct QueuedTrack: Hashable, Sendable {
    public let identifier: UUID
    public let track: Track

    public init(track: Track) {
        identifier = UUID()
        self.track = track
    }
}
