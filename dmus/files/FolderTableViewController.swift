#if os(iOS)
import DeveloperToolsSupport
import Model
import UIKit

final class FolderTableViewController: UITableViewController {
    private let folder: Folder
    private let player: Player

    init(folder: Folder, player: Player) {
        self.folder = folder
        self.player = player
        super.init(style: .plain)
        navigationItem.title = folder.name
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: UIButton.bordered(title: "Find"))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(FolderChildCell.self, forCellReuseIdentifier: FolderChildCell.reuseIdentifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        folder.children.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FolderChildCell.reuseIdentifier, for: indexPath)
            as! FolderChildCell
        let child = folder.children[indexPath.row]
        cell.show(
            child,
            onAdd: { [player] in player.queue.add(child) },
            onOpen: { [weak self] in self?.open(child) }
        )
        return cell
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch folder.children[indexPath.row] {
        case .folder: indexPath
        case .track: nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        open(folder.children[indexPath.row])
    }

    private func open(_ child: FolderChild) {
        guard case .folder(let folder) = child else { return }
        let folderTable = FolderTableViewController(folder: folder, player: player)
        navigationController?.pushViewController(folderTable, animated: true)
    }
}

#Preview {
    FolderTableViewController(
        folder: Folder(path: "/Music/Artist", name: "Artist", children: [
            .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [])),
            .track(Track(trackName: "Single", albumName: "Artist", artistName: Track.noArtist, path: "/Music/Artist/Single.m4a")),
        ]),
        player: Player()
    )
}
#endif
