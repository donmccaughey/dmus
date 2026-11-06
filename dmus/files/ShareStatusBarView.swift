#if os(macOS)
import AppKit
import DeveloperToolsSupport

final class ShareStatusBarView: NSView {
    private static let leadingPadding: CGFloat = 16
    // Lines the switch up with the accessory button in the panel title bar.
    private static let trailingPadding: CGFloat = 8
    private static let verticalPadding: CGFloat = 8
    private static let spacing: CGFloat = 8

    private let shareSwitch = NSSwitch()
    private let statusLabel = NSTextField(labelWithString: "")

    private var statusText: String {
        shareSwitch.state == .on ? "No device connected." : "Not sharing."
    }

    init() {
        super.init(frame: .zero)
        let titleLabel = NSTextField(labelWithString: "File Sharing")
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.maximumNumberOfLines = 1
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        shareSwitch.target = self
        shareSwitch.action = #selector(update)
        shareSwitch.setAccessibilityLabel("File Sharing")

        for subview in [titleLabel, statusLabel, shareSwitch] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.leadingPadding),
            titleLabel.centerYAnchor.constraint(equalTo: shareSwitch.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: Self.spacing),
            statusLabel.trailingAnchor.constraint(equalTo: shareSwitch.leadingAnchor, constant: -Self.spacing),
            statusLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor),
            shareSwitch.topAnchor.constraint(equalTo: topAnchor, constant: Self.verticalPadding),
            shareSwitch.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.trailingPadding),
            shareSwitch.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.verticalPadding),
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
    let view = ShareStatusBarView()
    view.frame = NSRect(x: 0, y: 0, width: 400, height: 38)
    return view
}
#endif
