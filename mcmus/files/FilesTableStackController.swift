#if os(iOS)
import DeveloperToolsSupport
import Model
import UIKit

final class FilesTableStackController: UINavigationController {
    private let player: Player
    private(set) var rootFolder: Folder?

    init(player: Player) {
        self.player = player
        super.init(nibName: nil, bundle: nil)
        drawOpaqueNavigationBar()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setRootFolder(_ folder: Folder) {
        // Reloading the same library must not pop the user back to the root.
        guard folder != rootFolder else { return }
        rootFolder = folder
        setViewControllers([FolderTableViewController(folder: folder, player: player)], animated: false)
    }

    private func drawOpaqueNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .secondarySystemBackground
        navigationBar.standardAppearance = appearance
        // Without this the bar turns transparent while the table is scrolled
        // to its top.
        navigationBar.scrollEdgeAppearance = appearance
    }
}

#Preview {
    let filesTableStack = FilesTableStackController(player: Player())
    filesTableStack.setRootFolder(Folder(
        path: "/Music",
        name: Folder.rootName,
        children: [
            .folder(Folder(path: "/Music/Artist", name: "Artist", children: [
                .folder(Folder(path: "/Music/Artist/Album", name: "Album", children: [
                    .track(Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3")),
                ])),
                .folder(Folder(path: "/Music/Artist/Empty", name: "Empty", children: [])),
            ])),
            .track(Track(trackName: "Loose", albumName: "(no album)", artistName: "(no artist)", path: "/Music/Loose.m4a")),
        ]
    ))
    return filesTableStack
}
#endif
