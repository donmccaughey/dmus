#if os(macOS)
import AppKit
import DeveloperToolsSupport
import Model

final class FilesPanelViewController: NSViewController {
    private let store: MusicLibraryStore
    private let findButton = NSButton(title: "Find", target: nil, action: nil)
    private let emptyFilesView = EmptyStateView(title: "No music", systemImage: "folder", description: "")
    private let treeView = FilesTreeView()
    private lazy var libraryView = NSStackView.bodyOverFooter(body: treeView, footer: ShareStatusBarView())
    private lazy var panelView = PanelView(title: "Files", accessory: findButton)

    init(store: MusicLibraryStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        findButton.bezelStyle = .push
        findButton.controlSize = .regular
        view = panelView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observeChanges { [weak self] in
            self?.update()
        }
    }

    private func update() {
        let library = store.library
        findButton.isEnabled = !library.isEmpty
        if library.isEmpty {
            emptyFilesView.descriptionText = store.loadDidFail
                ? "The music library did not load."
                : "The music library is empty."
            panelView.setContent(emptyFilesView)
        } else {
            treeView.setLibrary(library)
            panelView.setContent(libraryView)
        }
    }
}

#Preview("Empty") {
    FilesPanelViewController(store: MusicLibraryStore())
}

#Preview("Loaded") {
    let store = MusicLibraryStore()
    store.apply(LoadResult(library: MusicLibrary(rootFolder: Folder(
        path: "/Music",
        name: Folder.rootName,
        children: [
            Folder(path: "/Music/Artist", name: "Artist", children: [
                Track(trackName: "Song", albumName: "Artist", artistName: Track.noArtist, path: "/Music/Artist/Song.mp3"),
            ]),
        ]
    )), errors: []))
    return FilesPanelViewController(store: store)
}
#endif
