import Foundation

// The same track can be queued more than once, so each entry gets its own
// identity instead of borrowing the track's.
public struct QueuedTrack: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let track: Track

    public init(_ track: Track) {
        id = UUID()
        self.track = track
    }
}
