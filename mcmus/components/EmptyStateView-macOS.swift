#if os(macOS)
import AppKit
import DeveloperToolsSupport

final class EmptyStateView: NSView {
    private let descriptionLabel: NSTextField

    var descriptionText: String {
        get { descriptionLabel.stringValue }
        set { descriptionLabel.stringValue = newValue }
    }

    init(title: String, systemImage: String, description: String) {
        descriptionLabel = NSTextField(labelWithString: description)
        super.init(frame: .zero)

        let imageView = NSImageView(image: NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)!)
        imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 36, weight: .regular)
        imageView.contentTintColor = .secondaryLabelColor

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: NSFont.preferredFont(forTextStyle: .largeTitle).pointSize, weight: .bold)
        titleLabel.textColor = .secondaryLabelColor

        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [imageView, titleLabel, descriptionLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.setCustomSpacing(24, after: imageView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

#Preview {
    let view = EmptyStateView(title: "No music", systemImage: "folder", description: "The music library is empty.")
    view.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
    return view
}
#endif
