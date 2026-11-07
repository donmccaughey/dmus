#if os(iOS)
import DeveloperToolsSupport
import UIKit

final class QueueTableView: UIView {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let dataSource = QueueTableDataSource()
    private var lastQueuedTrackID: UUID?

    init() {
        super.init(frame: .zero)
        tableView.allowsSelection = false
        tableView.register(QueuedTrackCellView.self, forCellReuseIdentifier: QueuedTrackCellView.reuseIdentifier)
        tableView.dataSource = dataSource
        updateRowHeight()
        addFillingSubview(tableView)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _: UITraitCollection) in
            self.updateRowHeight()
            self.tableView.reloadData()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setQueuedTracks(_ queuedTracks: [QueuedTrack]) {
        dataSource.queuedTracks = queuedTracks
        tableView.reloadData()
        guard let last = queuedTracks.last, last.identifier != lastQueuedTrackID else {
            lastQueuedTrackID = queuedTracks.last?.identifier
            return
        }
        lastQueuedTrackID = last.identifier
        scrollToEnd()
    }

    private func scrollToEnd() {
        // Tracks queued before this view came on screen, as when a second
        // window opens, were not just added and have no size to scroll in.
        guard window != nil else { return }
        let lastRow = IndexPath(row: dataSource.queuedTracks.count - 1, section: 0)
        tableView.scrollToRow(at: lastRow, at: .bottom, animated: false)
    }

    private func updateRowHeight() {
        tableView.rowHeight = QueuedTrackCellView.rowHeight(for: traitCollection)
    }
}

private final class QueueTableDataSource: NSObject, UITableViewDataSource {
    var queuedTracks: [QueuedTrack] = []

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        queuedTracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: QueuedTrackCellView.reuseIdentifier, for: indexPath)
            as! QueuedTrackCellView
        cell.show(queuedTracks[indexPath.row].track)
        return cell
    }
}

#Preview {
    let tableView = QueueTableView()
    tableView.setQueuedTracks([
        Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3"),
        Track(trackName: "Loose", albumName: Track.noAlbum, artistName: Track.noArtist, path: "/Music/Loose.m4a"),
        Track(
            trackName: "A Track Name Long Enough That It Must Be Elided To Fit The Row",
            albumName: "An Album Name Long Enough That It Must Be Elided To Fit",
            artistName: "An Artist Name Long Enough That It Must Be Elided",
            path: "/Music/Artist/Album/Long.mp3"
        ),
        Track(
            trackName: "Song",
            albumName: "An Album Name Long Enough To Need More Than Sixty Percent Of The Row",
            artistName: "Artist",
            path: "/Music/Artist/Album/Song.mp3"
        ),
        Track(
            trackName: "Song",
            albumName: "Album",
            artistName: "An Artist Name Long Enough To Need More Than Forty Percent Of The Row",
            path: "/Music/Artist/Album/Song.mp3"
        ),
    ].map(QueuedTrack.init))
    return tableView
}
#endif
