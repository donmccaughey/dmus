#if os(macOS)
import AppKit

extension NSStackView {
    static func headerOverBody(header: NSView, body: NSView) -> NSStackView {
        let separator = NSBox()
        separator.boxType = .separator
        let stack = NSStackView(views: [header, separator, body])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.distribution = .fill
        // Stack alignment alone leaves a header that hugs its content at its
        // narrowest width, so pin every row to the full width.
        for row in [header, separator, body] {
            row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        // A separator box has no fixed thickness of its own, so without this
        // the stack stretches it over the space meant for the body.
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        body.setContentHuggingPriority(.defaultLow, for: .vertical)
        return stack
    }
}
#endif
