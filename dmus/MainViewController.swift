#if os(macOS)
import AppKit
import Model
import SwiftUI

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
        let queuePanel = makeQueuePanel()
        for subview in [filesPanel.view, separator, queuePanel] {
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
            queuePanel.leadingAnchor.constraint(equalTo: separator.trailingAnchor),
            queuePanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            queuePanel.topAnchor.constraint(equalTo: view.topAnchor),
            queuePanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            queuePanel.widthAnchor.constraint(equalTo: filesPanel.view.widthAnchor),
        ])
        constrainMinimumSize()
    }

    // Hosts the SwiftUI queue panel until it is rewritten in AppKit.
    private func makeQueuePanel() -> NSView {
        let hostingView = NSHostingView(rootView: QueuePanel().environment(player))
        hostingView.sizingOptions = []
        return hostingView
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
