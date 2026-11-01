import Foundation

protocol Audio: AnyObject {
    var playbackPosition: TimeInterval { get }
    var onTrackFinished: (() -> Void)? { get set }
    var onPlaybackPositionChanged: ((TimeInterval) -> Void)? { get set }

    func play(_ track: Track, from timeIndex: TimeInterval, thenPlay nextTrack: Track?)
    func replaceNextTrack(with nextTrack: Track?)
    func stop()
}
