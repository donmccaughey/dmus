import Foundation

final class AudioFake: Audio {
    enum Call: Equatable {
        case play(Track, from: TimeInterval, thenPlay: Track?)
        case replaceNextTrack(Track?)
        case stop
    }

    private(set) var calls: [Call] = []
    private(set) var currentTrack: Track?
    private(set) var nextTrack: Track?
    private(set) var isPlaying = false
    var playbackPosition: TimeInterval = 0
    var onTrackFinished: (() -> Void)?
    var onPlaybackPositionChanged: ((TimeInterval) -> Void)?

    func play(_ track: Track, from timeIndex: TimeInterval, thenPlay nextTrack: Track?) {
        calls.append(.play(track, from: timeIndex, thenPlay: nextTrack))
        currentTrack = track
        self.nextTrack = nextTrack
        playbackPosition = timeIndex
        isPlaying = true
    }

    func replaceNextTrack(with nextTrack: Track?) {
        calls.append(.replaceNextTrack(nextTrack))
        self.nextTrack = nextTrack
    }

    func stop() {
        calls.append(.stop)
        currentTrack = nil
        nextTrack = nil
        isPlaying = false
    }

    func clearCalls() {
        calls = []
    }

    // Mirrors the real wrapper, which has already advanced to the next track
    // by the time it reports the finished one.
    func finishCurrentTrack() {
        currentTrack = nextTrack
        nextTrack = nil
        playbackPosition = 0
        isPlaying = currentTrack != nil
        onTrackFinished?()
    }

    func reportPosition(_ position: TimeInterval) {
        playbackPosition = position
        onPlaybackPositionChanged?(position)
    }
}
