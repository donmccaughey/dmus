#if os(macOS)
import AppKit

final class ReadOnlyTextField: NSTextField {
    init() {
        super.init(frame: .zero)
        isEditable = false
        isSelectable = true
        isBezeled = true
        maximumNumberOfLines = 1
        lineBreakMode = .byTruncatingMiddle
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        // While text is selected the field editor lays out the full,
        // untruncated string, which would spill over neighboring controls.
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // refusesFirstResponder would also stop a mouse click from selecting the
    // text, so only the key view loop (Tab order and initial focus) is opted out.
    override var canBecomeKeyView: Bool { false }

    func setText(_ text: String) {
        guard stringValue != text else { return }
        // Otherwise a selection made before choosing a new path comes back as
        // the whole new value selected.
        abortEditing()
        stringValue = text
    }
}
#endif
