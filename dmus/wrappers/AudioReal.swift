import AVFoundation
import Foundation

final class AudioReal: Audio {
    private let player = AVQueuePlayer()
    // The queue player drops a finished item before posting its notification,
    // so items are tracked here to tell ours apart from other players' items.
    private var ownedItems: Set<AVPlayerItem> = []
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
        insert(track)
        replaceNextTrack(with: nextTrack)
        // AVPlayer clamps a seek past the end to the item's duration.
        player.seek(to: CMTime(seconds: timeIndex, preferredTimescale: 600))
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        player.play()
    }

    func replaceNextTrack(with nextTrack: Track?) {
        for item in player.items().dropFirst() {
            player.remove(item)
            ownedItems.remove(item)
        }
        if let nextTrack {
            insert(nextTrack)
        }
    }

    func stop() {
        player.pause()
        removeAllItems()
    }

    private func insert(_ track: Track) {
        let item = AVPlayerItem(url: URL(filePath: track.path))
        ownedItems.insert(item)
        player.insert(item, after: nil)
    }

    private func removeAllItems() {
        player.removeAllItems()
        ownedItems.removeAll()
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
        guard let item, ownedItems.contains(item) else { return }
        ownedItems.remove(item)
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
