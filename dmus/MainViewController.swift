#if os(macOS)
import AppKit
import Model

final class MainViewController: NSViewController {
    private let store: MusicLibraryStore
    private let player: Player

    init(store: MusicLibraryStore, player: Player) {
        self.store = store
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 600))
        let filesPanel = FilesPanelViewController(store: store)
        addChild(filesPanel)
        let separator = NSBox()
        separator.boxType = .separator
        let queuePanel = QueuePanelViewController(player: player)
        addChild(queuePanel)
        for subview in [filesPanel.view, separator, queuePanel.view] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            filesPanel.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filesPanel.view.topAnchor.constraint(equalTo: view.topAnchor),
            filesPanel.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: filesPanel.view.trailingAnchor),
            separator.widthAnchor.constraint(equalToConstant: 1),
            separator.topAnchor.constraint(equalTo: view.topAnchor),
            separator.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            queuePanel.view.leadingAnchor.constraint(equalTo: separator.trailingAnchor),
            queuePanel.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            queuePanel.view.topAnchor.constraint(equalTo: view.topAnchor),
            queuePanel.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            queuePanel.view.widthAnchor.constraint(equalTo: filesPanel.view.widthAnchor),
        ])
        constrainMinimumSize()
    }

    // The window takes its minimum size from its content view's constraints
    // and ignores contentMinSize once it has a content view controller.
    private func constrainMinimumSize() {
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(greaterThanOrEqualToConstant: 640),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 480),
        ])
    }
}
#endif
