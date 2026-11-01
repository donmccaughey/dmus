import AVFoundation
import Foundation

final class AudioReal: Audio {
    private let player = AVQueuePlayer()
    // The queue player still reports a finished item as current when it posts
    // the end notification, so items() cannot tell current from next.
    private var currentItem: AVPlayerItem?
    private var nextItem: AVPlayerItem?
    private var finishedObservers: [any NSObjectProtocol] = []
    private var positionObserver: Any?

    var onTrackFinished: (() -> Void)?
    var onPlaybackPositionChanged: ((TimeInterval) -> Void)?

    init() {
        player.actionAtItemEnd = .advance
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        #endif
        observeFinishedItems()
        observePosition()
    }

    deinit {
        for observer in finishedObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        if let positionObserver {
            player.removeTimeObserver(positionObserver)
        }
    }

    var playbackPosition: TimeInterval {
        Self.seconds(player.currentTime())
    }

    func play(_ track: Track, from timeIndex: TimeInterval, thenPlay nextTrack: Track?) {
        removeAllItems()
        currentItem = insert(track)
        replaceNextTrack(with: nextTrack)
        // AVPlayer clamps a seek past the end to the item's duration.
        player.seek(to: CMTime(seconds: timeIndex, preferredTimescale: 600))
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        player.play()
    }

    func replaceNextTrack(with nextTrack: Track?) {
        if let nextItem {
            player.remove(nextItem)
        }
        nextItem = nextTrack.map(insert)
    }

    func stop() {
        player.pause()
        removeAllItems()
    }

    private func insert(_ track: Track) -> AVPlayerItem {
        let item = AVPlayerItem(url: URL(filePath: track.path))
        player.insert(item, after: nil)
        return item
    }

    private func removeAllItems() {
        player.removeAllItems()
        currentItem = nil
        nextItem = nil
    }

    private static func seconds(_ time: CMTime) -> TimeInterval {
        time.seconds.isFinite ? max(0, time.seconds) : 0
    }

    // A failed item is reported as finished so the player advances past it
    // instead of waiting forever.
    private func observeFinishedItems() {
        let names: [Notification.Name] = [
            AVPlayerItem.didPlayToEndTimeNotification,
            AVPlayerItem.failedToPlayToEndTimeNotification,
        ]
        for name in names {
            let observer = NotificationCenter.default.addObserver(
                forName: name, object: nil, queue: .main
            ) { [weak self] notification in
                let item = notification.object as? AVPlayerItem
                MainActor.assumeIsolated {
                    self?.itemDidFinish(item)
                }
            }
            finishedObservers.append(observer)
        }
    }

    private func itemDidFinish(_ item: AVPlayerItem?) {
        guard let item, item == currentItem else { return }
        currentItem = nextItem
        nextItem = nil
        onTrackFinished?()
    }

    private func observePosition() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        positionObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                self?.onPlaybackPositionChanged?(Self.seconds(time))
            }
        }
    }
}
