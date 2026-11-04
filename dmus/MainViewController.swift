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

    // Hosts the SwiftUI panels until they are rewritten in AppKit.
    override func loadView() {
        let hostingView = NSHostingView(rootView: MainView().environment(store).environment(player))
        // The window controls its own size and minimum size, so the hosted
        // view must not impose its own.
        hostingView.sizingOptions = []
        hostingView.frame = NSRect(x: 0, y: 0, width: 900, height: 600)
        view = hostingView
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
