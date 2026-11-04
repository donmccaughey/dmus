#if os(macOS)
import AppKit
import DeveloperToolsSupport

final class PanelView: NSView {
    private let contentContainer = NSView()
    private var contentView: NSView?

    init(title: String, accessory: NSView? = nil) {
        super.init(frame: .zero)
        let titleBar = Self.makeTitleBar(title: title, accessory: accessory)
        let separator = NSBox()
        separator.boxType = .separator
        for subview in [titleBar, separator, contentContainer] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            titleBar.topAnchor.constraint(equalTo: topAnchor),
            titleBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.topAnchor.constraint(equalTo: titleBar.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.topAnchor.constraint(equalTo: separator.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setContent(_ view: NSView) {
        guard view !== contentView else { return }
        contentView?.removeFromSuperview()
        contentView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])
    }

    private static func makeTitleBar(title: String, accessory: NSView?) -> NSView {
        let titleBar = NSVisualEffectView()
        titleBar.material = .titlebar
        titleBar.blendingMode = .withinWindow

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleBar.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: titleBar.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: titleBar.topAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: titleBar.bottomAnchor, constant: -16),
        ])

        if let accessory {
            accessory.translatesAutoresizingMaskIntoConstraints = false
            titleBar.addSubview(accessory)
            NSLayoutConstraint.activate([
                accessory.trailingAnchor.constraint(equalTo: titleBar.trailingAnchor, constant: -8),
                accessory.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
            ])
        }
        return titleBar
    }
}

#Preview {
    let panel = PanelView(title: "Panel")
    panel.setContent(NSTextField(labelWithString: "Content"))
    panel.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
    return panel
}

#Preview("Accessory") {
    let button = NSButton(title: "Action", target: nil, action: nil)
    button.bezelStyle = .push
    let panel = PanelView(title: "Panel", accessory: button)
    panel.setContent(NSTextField(labelWithString: "Content"))
    panel.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
    return panel
}
#endif
