#if os(macOS)
import AppKit
import SwiftUI

struct ReadOnlyTextField: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = TabSkippingTextField(string: text)
        textField.isEditable = false
        textField.isSelectable = true
        textField.lineBreakMode = .byTruncatingMiddle
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // While text is selected the field editor lays out the full,
        // untruncated string, which would spill over neighboring controls.
        textField.clipsToBounds = true
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        guard textField.stringValue != text else { return }
        // Otherwise a selection made before choosing a new path comes back as
        // the whole new value selected.
        textField.abortEditing()
        textField.stringValue = text
    }
}

// refusesFirstResponder would also stop a mouse click from selecting the
// text, so only the key view loop (Tab order and initial focus) is opted out.
private final class TabSkippingTextField: NSTextField {
    override var canBecomeKeyView: Bool { false }
}
#endif
