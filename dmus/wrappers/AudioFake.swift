import Foundation

final class AudioFake: Audio {
    enum Call: Equatable {
        case play(URL, from: TimeInterval, thenPlay: URL?)
        case replaceNextTrack(URL?)
        case stop
    }

    private(set) var calls: [Call] = []
    private(set) var currentTrackURL: URL?
    private(set) var nextTrackURL: URL?
    private(set) var isPlaying = false
    var playbackPosition: TimeInterval = 0
    var onTrackFinished: (() -> Void)?
    var onPlaybackPositionChanged: ((TimeInterval) -> Void)?

    func play(_ trackURL: URL, from timeIndex: TimeInterval, thenPlay nextTrackURL: URL?) {
        calls.append(.play(trackURL, from: timeIndex, thenPlay: nextTrackURL))
        currentTrackURL = trackURL
        self.nextTrackURL = nextTrackURL
        playbackPosition = timeIndex
        isPlaying = true
    }

    func replaceNextTrack(with nextTrackURL: URL?) {
        calls.append(.replaceNextTrack(nextTrackURL))
        self.nextTrackURL = nextTrackURL
    }

    func stop() {
        calls.append(.stop)
        currentTrackURL = nil
        nextTrackURL = nil
        isPlaying = false
    }

    func clearCalls() {
        calls = []
    }

    // Mirrors the real wrapper, which has already advanced to the next track
    // by the time it reports the finished one.
    func finishCurrentTrack() {
        currentTrackURL = nextTrackURL
        nextTrackURL = nil
        playbackPosition = 0
        isPlaying = currentTrackURL != nil
        onTrackFinished?()
    }

    func reportPosition(_ position: TimeInterval) {
        playbackPosition = position
        onPlaybackPositionChanged?(position)
    }
}
