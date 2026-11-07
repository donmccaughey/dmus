import Foundation
import Wrappers

@MainActor
public final class Player: NSObject {
    // Posted when isPlaying changes; timeIndex ticks twice a second while
    // playing and no view shows it, so it posts nothing.
    public static let didChangeNotification = Notification.Name("PlayerDidChange")

    public let audio: any Audio
    public let queue: Queue
    private(set) public var timeIndex: TimeInterval = 0
    private(set) public var isPlaying = false
    private var isMutatingQueue = false

    public init(audio: any Audio) {
        self.audio = audio
        queue = Queue()
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queueDidChange),
            name: Queue.didChangeNotification,
            object: queue
        )
        audio.onTrackFinished = { [weak self] in self?.audioDidFinishCurrentTrack() }
        audio.onPlaybackPositionChanged = { [weak self] position in
            self?.audioPositionDidChange(to: position)
        }
    }

    public override convenience init() {
        self.init(audio: AudioReal())
    }

    public var currentTrack: Track? {
        queue.tracks.first
    }

    public var nextTrack: Track? {
        queue.tracks.dropFirst().first
    }

    public func play() {
        guard let currentTrack, !isPlaying else { return }
        audio.play(currentTrack.url, from: timeIndex, thenPlay: nextTrack?.url)
        setIsPlaying(true)
    }

    public func stop() {
        guard !queue.isEmpty, isPlaying else { return }
        timeIndex = audio.playbackPosition
        stopAudio()
    }

    public func back() {
        guard let currentTrack else { return }
        timeIndex = 0
        if isPlaying {
            audio.play(currentTrack.url, from: 0, thenPlay: nextTrack?.url)
        }
    }

    public func next() {
        guard !queue.isEmpty else { return }
        timeIndex = 0
        mutateQueue { queue.removeFirst() }
        guard isPlaying else { return }
        if let currentTrack {
            audio.play(currentTrack.url, from: 0, thenPlay: nextTrack?.url)
        } else {
            stopAudio()
        }
    }

    public func clear() {
        guard !queue.isEmpty else { return }
        timeIndex = 0
        mutateQueue { queue.clear() }
        if isPlaying {
            stopAudio()
        }
    }

    private func stopAudio() {
        audio.stop()
        setIsPlaying(false)
    }

    // Every caller has checked that the value changes, so this posts once per
    // command, after the command's other state is settled.
    private func setIsPlaying(_ isPlaying: Bool) {
        self.isPlaying = isPlaying
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    // The player's own commands tell the audio wrapper what to play next
    // themselves, so only changes made by others need syncing here.
    private func mutateQueue(_ mutate: () -> Void) {
        isMutatingQueue = true
        mutate()
        isMutatingQueue = false
    }

    @objc private func queueDidChange() {
        guard isPlaying, !isMutatingQueue else { return }
        audio.replaceNextTrack(with: nextTrack?.url)
    }

    // The audio wrapper has already moved on to the next track, so only the
    // queue needs to catch up.
    private func audioDidFinishCurrentTrack() {
        guard isPlaying else { return }
        timeIndex = 0
        mutateQueue { queue.removeFirst() }
        if queue.isEmpty {
            setIsPlaying(false)
        } else {
            audio.replaceNextTrack(with: nextTrack?.url)
        }
    }

    private func audioPositionDidChange(to position: TimeInterval) {
        if isPlaying {
            timeIndex = position
        }
    }
}
