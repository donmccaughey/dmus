#if os(iOS)
import DeveloperToolsSupport
import Model
import UIKit

final class FilesPanelViewController: UIViewController {
    private let store: MusicLibraryStore
    private let emptyFilesView = EmptyStateView(title: "No music", systemImage: "folder", description: "")
    private let filesTableStack: FilesTableStackController
    private lazy var panelView = PanelView(title: "Files", accessory: Self.makePlaceholderFindButton())

    init(store: MusicLibraryStore, player: Player) {
        self.store = store
        filesTableStack = FilesTableStackController(player: player)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        view = panelView
        addChild(filesTableStack)
        filesTableStack.didMove(toParent: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observeChanges { [weak self] in
            self?.update()
        }
    }

    private func update() {
        let library = store.library
        if library.isEmpty {
            emptyFilesView.descriptionText = store.loadDidFail
                ? "The music library did not load."
                : "The music library is empty."
            panelView.showsTitle = true
            panelView.setContent(emptyFilesView)
        } else {
            // The root folder table's navigation bar already shows the
            // "Files" title and a find button, so the panel title would
            // duplicate them.
            panelView.showsTitle = false
            filesTableStack.setRootFolder(library.rootFolder)
            panelView.setContent(filesTableStack.view)
        }
    }

    // The panel title only shows while the library is empty and there is
    // nothing to find; the active find button is the folder table's.
    private static func makePlaceholderFindButton() -> UIButton {
        let findButton = UIButton.bordered(title: "Find")
        findButton.isEnabled = false
        return findButton
    }
}

#Preview("Empty") {
    FilesPanelViewController(store: MusicLibraryStore(), player: Player())
}

#Preview("Loaded") {
    let store = MusicLibraryStore()
    store.apply(LoadResult(library: MusicLibrary(rootFolder: Folder(
        path: "/Music",
        name: Folder.rootName,
        children: [
            .folder(Folder(path: "/Music/Artist", name: "Artist", children: [
                .track(Track(trackName: "Song", albumName: "Artist", artistName: Track.noArtist, path: "/Music/Artist/Song.mp3")),
            ])),
        ]
    )), errors: []))
    return FilesPanelViewController(store: store, player: Player())
}
#endif
