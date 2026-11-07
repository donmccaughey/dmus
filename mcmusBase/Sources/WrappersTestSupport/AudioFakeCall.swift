import Foundation

public final class AudioFakeCall: NSObject, Sendable {
    private enum Kind: Sendable {
        case play
        case replaceNextTrack
        case stop
    }

    private let kind: Kind
    private let trackURL: URL?
    private let timeIndex: TimeInterval
    private let nextTrackURL: URL?

    private init(kind: Kind, trackURL: URL? = nil, timeIndex: TimeInterval = 0, nextTrackURL: URL? = nil) {
        self.kind = kind
        self.trackURL = trackURL
        self.timeIndex = timeIndex
        self.nextTrackURL = nextTrackURL
    }

    public static func play(_ trackURL: URL, from timeIndex: TimeInterval, thenPlay nextTrackURL: URL?) -> AudioFakeCall {
        AudioFakeCall(kind: .play, trackURL: trackURL, timeIndex: timeIndex, nextTrackURL: nextTrackURL)
    }

    public static func replaceNextTrack(_ nextTrackURL: URL?) -> AudioFakeCall {
        AudioFakeCall(kind: .replaceNextTrack, nextTrackURL: nextTrackURL)
    }

    public static var stop: AudioFakeCall {
        AudioFakeCall(kind: .stop)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AudioFakeCall else { return false }
        return kind == other.kind
            && trackURL == other.trackURL
            && timeIndex == other.timeIndex
            && nextTrackURL == other.nextTrackURL
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(kind)
        hasher.combine(trackURL)
        hasher.combine(timeIndex)
        hasher.combine(nextTrackURL)
        return hasher.finalize()
    }

    public override var description: String {
        switch kind {
        case .play:
            "play(\(trackURL!.path), from: \(timeIndex), thenPlay: \(nextTrackURL?.path ?? "nil"))"
        case .replaceNextTrack:
            "replaceNextTrack(\(nextTrackURL?.path ?? "nil"))"
        case .stop:
            "stop"
        }
    }
}
