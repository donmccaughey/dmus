#if os(iOS)
import DeveloperToolsSupport
import Model
import UIKit

final class MainViewController: UIViewController {
    private let filesPanel: FilesPanelViewController
    private let queuePanel: QueuePanelViewController
    private let stack = UIStackView()
    private let separator = HairlineView()
    private var arrangement: PanelArrangement?
    private lazy var equalWidths = filesPanel.view.widthAnchor.constraint(equalTo: queuePanel.view.widthAnchor)
    private lazy var equalHeights = filesPanel.view.heightAnchor.constraint(equalTo: queuePanel.view.heightAnchor)

    init(store: MusicLibraryStore, player: Player) {
        filesPanel = FilesPanelViewController(store: store, player: player)
        queuePanel = QueuePanelViewController(player: player)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
        addChild(filesPanel)
        addChild(queuePanel)
        for subview in [filesPanel.view!, separator, queuePanel.view!] {
            stack.addArrangedSubview(subview)
        }
        view.addFillingSubview(stack)
        filesPanel.didMove(toParent: self)
        queuePanel.didMove(toParent: self)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        arrange(PanelArrangement(fitting: view.bounds.size))
        equalizeUsableAreas()
    }

    private func arrange(_ newArrangement: PanelArrangement) {
        guard newArrangement != arrangement else { return }
        arrangement = newArrangement
        NSLayoutConstraint.deactivate([equalWidths, equalHeights])
        switch newArrangement {
        case .sideBySide:
            stack.axis = .horizontal
            separator.axis = .vertical
            equalWidths.isActive = true
        case .stacked:
            stack.axis = .vertical
            separator.axis = .horizontal
            equalHeights.isActive = true
        }
    }

    // The panels run under the safe area insets, so the files panel gets
    // the difference between the insets on its side and the queue panel's
    // to leave both the same room inside the safe area.
    private func equalizeUsableAreas() {
        let insets = view.safeAreaInsets
        equalWidths.constant = insets.left - insets.right
        equalHeights.constant = insets.top - insets.bottom
    }
}

#Preview("Portrait", traits: .portrait) {
    MainViewController(store: MusicLibraryStore(), player: Player())
}

#Preview("Landscape", traits: .landscapeLeft) {
    MainViewController(store: MusicLibraryStore(), player: Player())
}
#endif
