import Foundation
import Wrappers

public final class AudioFake: Audio {
    public enum Call: Equatable {
        case play(URL, from: TimeInterval, thenPlay: URL?)
        case replaceNextTrack(URL?)
        case stop
    }

    private(set) public var calls: [Call] = []
    private(set) var currentTrackURL: URL?
    private(set) var nextTrackURL: URL?
    private(set) var isPlaying = false
    public var playbackPosition: TimeInterval = 0
    public var onTrackFinished: (() -> Void)?
    public var onPlaybackPositionChanged: ((TimeInterval) -> Void)?

    public init() {}
    
    public func play(_ trackURL: URL, from timeIndex: TimeInterval, thenPlay nextTrackURL: URL?) {
        calls.append(.play(trackURL, from: timeIndex, thenPlay: nextTrackURL))
        currentTrackURL = trackURL
        self.nextTrackURL = nextTrackURL
        playbackPosition = timeIndex
        isPlaying = true
    }

    public func replaceNextTrack(with nextTrackURL: URL?) {
        calls.append(.replaceNextTrack(nextTrackURL))
        self.nextTrackURL = nextTrackURL
    }

    public func stop() {
        calls.append(.stop)
        currentTrackURL = nil
        nextTrackURL = nil
        isPlaying = false
    }

    public func clearCalls() {
        calls = []
    }

    // Mirrors the real wrapper, which has already advanced to the next track
    // by the time it reports the finished one.
    public func finishCurrentTrack() {
        currentTrackURL = nextTrackURL
        nextTrackURL = nil
        playbackPosition = 0
        isPlaying = currentTrackURL != nil
        onTrackFinished?()
    }

    public func reportPosition(_ position: TimeInterval) {
        playbackPosition = position
        onPlaybackPositionChanged?(position)
    }
}
