import Foundation
import Observation

@Observable
final class Player {
    let audio: any Audio
    let queue: Queue
    private(set) var timeIndex: TimeInterval = 0
    private(set) var isPlaying = false
    private var isMutatingQueue = false

    init(audio: any Audio, queue: Queue = Queue()) {
        self.audio = audio
        self.queue = queue
        queue.onChange = { [weak self] in self?.queueDidChange() }
        audio.onTrackFinished = { [weak self] in self?.audioDidFinishCurrentTrack() }
        audio.onPlaybackPositionChanged = { [weak self] position in
            self?.audioPositionDidChange(to: position)
        }
    }

    var currentTrack: Track? {
        queue.tracks.first
    }

    var nextTrack: Track? {
        queue.tracks.dropFirst().first
    }

    func play() {
        guard let currentTrack, !isPlaying else { return }
        audio.play(currentTrack.url, from: timeIndex, thenPlay: nextTrack?.url)
        isPlaying = true
    }

    func stop() {
        guard !queue.isEmpty, isPlaying else { return }
        timeIndex = audio.playbackPosition
        stopAudio()
    }

    func back() {
        guard let currentTrack else { return }
        timeIndex = 0
        if isPlaying {
            audio.play(currentTrack.url, from: 0, thenPlay: nextTrack?.url)
        }
    }

    func next() {
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

    func clear() {
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
