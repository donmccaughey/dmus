import Foundation

protocol Audio: AnyObject {
    var playbackPosition: TimeInterval { get }
    var onTrackFinished: (() -> Void)? { get set }
    var onPlaybackPositionChanged: ((TimeInterval) -> Void)? { get set }

    func play(_ trackURL: URL, from timeIndex: TimeInterval, thenPlay nextTrackURL: URL?)
    func replaceNextTrack(with nextTrackURL: URL?)
    func stop()
}
