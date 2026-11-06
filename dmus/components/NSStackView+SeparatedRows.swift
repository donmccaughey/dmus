#if os(macOS)
import AppKit

extension NSStackView {
    static func headerOverBody(header: NSView, body: NSView) -> NSStackView {
        separatedRows(top: header, bottom: body, stretching: body)
    }

    static func bodyOverFooter(body: NSView, footer: NSView) -> NSStackView {
        separatedRows(top: body, bottom: footer, stretching: body)
    }

    private static func separatedRows(top: NSView, bottom: NSView, stretching body: NSView) -> NSStackView {
        let separator = NSBox()
        separator.boxType = .separator
        let rows = [top, separator, bottom]
        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.distribution = .fill
        // Stack alignment alone leaves a row that hugs its content at its
        // narrowest width, so pin every row to the full width.
        for row in rows {
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
