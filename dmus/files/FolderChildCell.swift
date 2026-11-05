#if os(iOS)
import Model
import UIKit

final class FolderChildCell: UITableViewCell {
    static let reuseIdentifier = "FolderChildCell"

    private let addButton = makeRowButton(accessibilityLabel: "Add")
    private let openButton = makeRowButton(accessibilityLabel: "Open")
    private let accessoryStack = UIStackView()
    private var onAdd: () -> Void = {}
    private var onOpen: () -> Void = {}

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addButton.addAction(UIAction { [weak self] _ in self?.onAdd() }, for: .primaryActionTriggered)
        openButton.configuration?.image = UIImage(systemName: "chevron.right")
        openButton.configuration?.baseForegroundColor = .tertiaryLabel
        openButton.addAction(UIAction { [weak self] _ in self?.onOpen() }, for: .primaryActionTriggered)
        accessoryStack.addArrangedSubview(addButton)
        accessoryStack.addArrangedSubview(openButton)
        accessoryView = accessoryStack
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(_ child: FolderChild, onAdd: @escaping () -> Void, onOpen: @escaping () -> Void) {
        self.onAdd = onAdd
        self.onOpen = onOpen
        var content = defaultContentConfiguration()
        content.text = child.name
        contentConfiguration = content
        switch child {
        case .folder:
            addButton.configuration?.image = UIImage(systemName: "plus.square")
            openButton.isHidden = false
            selectionStyle = .default
        case .track:
            addButton.configuration?.image = UIImage(systemName: "plus.circle")
            openButton.isHidden = true
            selectionStyle = .none
        }
        sizeAccessoryToFit()
    }

    // A cell places its accessory view by the view's frame and ignores its
    // constraints.
    private func sizeAccessoryToFit() {
        accessoryStack.frame.size = accessoryStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    // The leading inset spaces the symbols and widens their touch targets;
    // no trailing inset keeps the last symbol on the cell's trailing margin.
    private static func makeRowButton(accessibilityLabel: String) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0)
        let button = UIButton(configuration: configuration)
        button.accessibilityLabel = accessibilityLabel
        return button
    }
}
#endif
