import Foundation
import Observation
import Wrappers

@Observable @MainActor
public final class Player {
    public let audio: any Audio
    public let queue: Queue
    private(set) public var timeIndex: TimeInterval = 0
    private(set) public var isPlaying = false
    private var isMutatingQueue = false

    public init(audio: any Audio) {
        self.audio = audio
        queue = Queue()
        queue.onChange = { [weak self] in self?.queueDidChange() }
        audio.onTrackFinished = { [weak self] in self?.audioDidFinishCurrentTrack() }
        audio.onPlaybackPositionChanged = { [weak self] position in
            self?.audioPositionDidChange(to: position)
        }
    }

    public convenience init() {
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
        isPlaying = true
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
        isPlaying = false
    }

    // The player's own commands tell the audio wrapper what to play next
    // themselves, so only changes made by others need syncing here.
    private func mutateQueue(_ mutate: () -> Void) {
        isMutatingQueue = true
        mutate()
        isMutatingQueue = false
    }

    private func queueDidChange() {
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
            isPlaying = false
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
