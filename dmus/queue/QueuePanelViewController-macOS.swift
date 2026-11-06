#if os(macOS)
import AppKit
import DeveloperToolsSupport
import Model
import Wrappers

final class QueuePanelViewController: NSViewController {
    private let player: Player
    private let clearButton = NSButton(title: "Clear", target: nil, action: nil)
    private let emptyQueueView = EmptyStateView(
        title: "No tracks",
        systemImage: "list.bullet",
        description: "The queue is empty."
    )
    private let queueTableView = QueueTableView()
    private let dropTargetView = DropTargetView()
    private lazy var panelView = PanelView(title: "Queue", accessory: clearButton)

    init(player: Player) {
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        clearButton.bezelStyle = .push
        clearButton.controlSize = .regular
        clearButton.target = self
        clearButton.action = #selector(clear)
        dropTargetView.onDrop = { [weak self] children in
            self?.player.queue.add(children)
        }
        let queueBody = NSView()
        queueBody.addFillingSubview(emptyQueueView)
        queueBody.addFillingSubview(queueTableView)
        dropTargetView.setContent(NSStackView.headerOverBody(
            header: PlayerPanelView(player: player),
            body: queueBody
        ))
        panelView.setContent(dropTargetView)
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

    @objc private func clear() {
        player.clear()
    }
}

#Preview("Empty") {
    QueuePanelViewController(player: Player(audio: AudioReal()))
}

#Preview("Filled") {
    let player = Player(audio: AudioReal())
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
