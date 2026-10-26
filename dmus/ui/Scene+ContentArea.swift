import SwiftUI

#if os(macOS)
extension Scene {
    func defaultContentAreaSize(width: CGFloat, height: CGFloat) -> some Scene {
        // defaultSize() sets the overall window size
        // add the title bar height to the given content area height
        defaultSize(width: width, height: height + titleBarHeight)
    }
}

private let titleBarHeight: CGFloat = {
    let contentRect = NSRect(x: 0, y: 0, width: 100, height: 100)
    let frameRect = NSWindow.frameRect(forContentRect: contentRect, styleMask: .titled)
    return frameRect.height - contentRect.height
}()
#endif
