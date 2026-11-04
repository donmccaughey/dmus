#if os(macOS)
import AppKit
import Model

final class DropTargetView: NSView {
    var onDrop: (([FolderChild]) -> Void)?
    private var contentView: NSView?

    init() {
        super.init(frame: .zero)
        registerForDraggedTypes([.folderChild])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setContent(_ view: NSView) {
        guard view !== contentView else { return }
        contentView?.removeFromSuperview()
        contentView = view
        addFillingSubview(view)
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let children = FolderChild.folderChildren(in: sender.draggingPasteboard)
        guard !children.isEmpty else { return false }
        onDrop?(children)
        return true
    }
}
#endif
