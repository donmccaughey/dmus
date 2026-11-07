import AVFoundation
import Foundation

@MainActor
public final class AudioReal: Audio {
    private let player = AVQueuePlayer()
    // The queue player still reports a finished item as current when it posts
    // the end notification, so items() cannot tell current from next.
    private var currentItem: AVPlayerItem?
    private var nextItem: AVPlayerItem?
    private var finishedObservers: [any NSObjectProtocol] = []
    private var positionObserver: Any?

    public var onTrackFinished: (() -> Void)?
    public var onPlaybackPositionChanged: ((TimeInterval) -> Void)?

    public init() {
        player.actionAtItemEnd = .advance
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        #endif
        observeFinishedItems()
        observePosition()
    }

    isolated deinit {
        for observer in finishedObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        if let positionObserver {
            player.removeTimeObserver(positionObserver)
        }
    }

    public var playbackPosition: TimeInterval {
        Self.seconds(player.currentTime())
    }

    public func play(_ trackURL: URL, from timeIndex: TimeInterval, thenPlay nextTrackURL: URL?) {
        removeAllItems()
        currentItem = insert(trackURL)
        replaceNextTrack(with: nextTrackURL)
        // AVPlayer clamps a seek past the end to the item's duration.
        player.seek(to: CMTime(seconds: timeIndex, preferredTimescale: 600))
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        player.play()
    }

    public func replaceNextTrack(with nextTrackURL: URL?) {
        if let nextItem {
            player.remove(nextItem)
        }
        nextItem = nextTrackURL.map(insert)
    }

    public func stop() {
        player.pause()
        removeAllItems()
    }

    private func insert(_ trackURL: URL) -> AVPlayerItem {
        let item = AVPlayerItem(url: trackURL)
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
