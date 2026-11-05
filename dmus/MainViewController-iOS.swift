#if os(iOS)
import Model
import SwiftUI
import UIKit

final class MainViewController: UIViewController {
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

    // Hosts the SwiftUI main view until the UIKit panels replace it.
    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        let hosted = UIHostingController(rootView: MainView().environment(store).environment(player))
        addChild(hosted)
        hosted.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosted.view)
        NSLayoutConstraint.activate([
            hosted.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosted.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosted.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosted.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosted.didMove(toParent: self)
    }
}

#Preview("Portrait", traits: .portrait) {
    MainViewController(store: MusicLibraryStore(), player: Player())
}

#Preview("Landscape", traits: .landscapeLeft) {
    MainViewController(store: MusicLibraryStore(), player: Player())
}
#endif
