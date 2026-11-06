#if os(macOS)
import AppKit
import DeveloperToolsSupport

final class SharePanelView: NSView {
    private static let leadingPadding: CGFloat = 16
    // Lines the switch up with the accessory button in the panel title bar.
    private static let trailingPadding: CGFloat = 8
    private static let verticalPadding: CGFloat = 12
    private static let lineSpacing: CGFloat = 2
    private static let labelToSwitchSpacing: CGFloat = 8

    private let shareSwitch = NSSwitch()
    private let statusLabel = NSTextField(labelWithString: "")

    private var statusText: String {
        shareSwitch.state == .on ? "No device connected." : "Not sharing."
    }

    init() {
        super.init(frame: .zero)
        let titleLabel = NSTextField(labelWithString: "File Sharing")
        titleLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.maximumNumberOfLines = 1
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        shareSwitch.target = self
        shareSwitch.action = #selector(update)
        shareSwitch.setAccessibilityLabel("File Sharing")

        for subview in [titleLabel, shareSwitch, statusLabel] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Self.verticalPadding),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.leadingPadding),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: shareSwitch.leadingAnchor,
                constant: -Self.labelToSwitchSpacing
            ),
            shareSwitch.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.trailingPadding),
            shareSwitch.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Self.lineSpacing),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.leadingPadding),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.trailingPadding),
            statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.verticalPadding),
        ])
        setContentHuggingPriority(.required, for: .vertical)
        update()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func update() {
        statusLabel.stringValue = statusText
    }
}

#Preview {
    let view = SharePanelView()
    view.frame = NSRect(x: 0, y: 0, width: 400, height: 60)
    return view
}
#endif
