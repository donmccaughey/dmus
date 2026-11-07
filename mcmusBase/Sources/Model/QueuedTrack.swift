import Foundation

// The same track can be queued more than once, so each entry gets its own
// identity instead of borrowing the track's.
public final class QueuedTrack: NSObject, Sendable {
    public let identifier: UUID
    public let track: Track

    public init(track: Track) {
        identifier = UUID()
        self.track = track
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? QueuedTrack else { return false }
        return identifier == other.identifier && track == other.track
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(identifier)
        hasher.combine(track)
        return hasher.finalize()
    }
}
