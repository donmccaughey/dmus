#if os(iOS)
import DeveloperToolsSupport
import UIKit

final class PanelView: UIView {
    private let titleBar: UIView
    private let titleSeparator = HairlineView()
    private let contentContainer = UIView()
    private var contentView: UIView?

    var showsTitle = true {
        didSet {
            titleBar.isHidden = !showsTitle
            titleSeparator.isHidden = !showsTitle
        }
    }

    init(title: String, accessory: UIView? = nil) {
        titleBar = Self.makeTitleBar(title: title, accessory: accessory)
        super.init(frame: .zero)
        let stack = UIStackView(arrangedSubviews: [titleBar, titleSeparator, contentContainer])
        stack.axis = .vertical
        addFillingSubview(stack)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setContent(_ view: UIView) {
        guard view !== contentView else { return }
        contentView?.removeFromSuperview()
        contentView = view
        contentContainer.addFillingSubview(view)
    }

    private static func makeTitleBar(title: String, accessory: UIView?) -> UIView {
        let titleBar = UIView()
        // The folder table's navigation bar uses the same color and rows
        // scroll underneath it, so this must be solid rather than a material.
        titleBar.backgroundColor = .secondarySystemBackground

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        // The label's height sets the title bar's, so the content has to be
        // what stretches or shrinks to fill the panel.
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleBar.addSubview(titleLabel)
        // The background runs under the status bar and the notch while the
        // title and accessory stay clear of them.
        let safeArea = titleBar.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),
        ])

        if let accessory {
            accessory.translatesAutoresizingMaskIntoConstraints = false
            titleBar.addSubview(accessory)
            NSLayoutConstraint.activate([
                accessory.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -8),
                accessory.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            ])
        }
        return titleBar
    }
}

private func makePreviewContent() -> UILabel {
    let label = UILabel()
    label.text = "Content"
    label.textAlignment = .center
    return label
}

#Preview {
    let panel = PanelView(title: "Panel")
    panel.setContent(makePreviewContent())
    return panel
}

#Preview("Accessory") {
    var configuration = UIButton.Configuration.bordered()
    configuration.title = "Action"
    let panel = PanelView(title: "Panel", accessory: UIButton(configuration: configuration))
    panel.setContent(makePreviewContent())
    return panel
}
#endif
