#if os(iOS)
import DeveloperToolsSupport
import Model
import UIKit

final class QueuePanelViewController: UIViewController {
    private let player: Player
    private let clearButton: UIButton
    private let emptyQueueView = EmptyStateView(
        title: "No tracks",
        systemImage: "list.bullet",
        description: "The queue is empty."
    )
    private let queueTableView = QueueTableView()
    private lazy var queueView = makeQueueView()
    private lazy var panelView = PanelView(title: "Queue", accessory: clearButton)

    init(player: Player) {
        self.player = player
        clearButton = UIButton.bordered(title: "Clear", primaryAction: UIAction { [player] _ in player.clear() })
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        panelView.setContent(queueView)
        view = panelView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observeChanges { [weak self] in
            self?.update()
        }
    }

    private func update() {
        let queuedTracks = player.queue.queuedTracks
        clearButton.isEnabled = !queuedTracks.isEmpty
        emptyQueueView.isHidden = !queuedTracks.isEmpty
        queueTableView.isHidden = queuedTracks.isEmpty
        queueTableView.setQueuedTracks(queuedTracks)
    }

    private func makeQueueView() -> UIView {
        let queueBody = UIView()
        queueBody.addFillingSubview(emptyQueueView)
        queueBody.addFillingSubview(queueTableView)
        let stack = UIStackView(arrangedSubviews: [PlayerPanelView(player: player), HairlineView(), queueBody])
        stack.axis = .vertical
        return stack
    }
}

#Preview("Empty") {
    QueuePanelViewController(player: Player())
}

#Preview("Filled") {
    let player = Player()
    player.queue.add(Folder(path: "/Music/Artist", name: "Artist", children: [
        .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
            .track(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3")),
            .track(Track(trackName: "Another Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Another Song.mp3")),
        ])),
        .track(Track(trackName: "Single", albumName: "Artist", artistName: Track.noArtist, path: "/Music/Artist/Single.m4a")),
        .track(Track(
            trackName: "A Track Name Long Enough That It Must Be Elided To Fit The Row",
            albumName: "An Album Name Long Enough That It Must Be Elided To Fit",
            artistName: "An Artist Name Long Enough That It Must Be Elided",
            path: "/Music/Artist/Long.mp3"
        )),
    ]))
    return QueuePanelViewController(player: player)
}
#endif
