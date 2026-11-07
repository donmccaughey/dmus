#if os(macOS)
import AppKit
import DeveloperToolsSupport

final class QueueTableView: NSScrollView {
    private let tableView = NSTableView()
    private let dataSource = QueueTableDataSource()
    private var lastQueuedTrackID: UUID?

    init() {
        super.init(frame: .zero)
        tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("track")))
        tableView.headerView = nil
        tableView.style = .plain
        tableView.selectionHighlightStyle = .none
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.intercellSpacing = .zero
        tableView.rowHeight = QueuedTrackCellView.rowHeight
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        documentView = tableView
        hasVerticalScroller = true
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
        tableView.scrollRowToVisible(tableView.numberOfRows - 1)
    }
}

private final class QueueTableDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var queuedTracks: [QueuedTrack] = []

    func numberOfRows(in tableView: NSTableView) -> Int {
        queuedTracks.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: QueuedTrackCellView.reuseIdentifier, owner: nil) as? QueuedTrackCellView
            ?? QueuedTrackCellView()
        cell.show(queuedTracks[row].track)
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
    tableView.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
    return tableView
}
#endif
