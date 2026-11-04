#if os(macOS)
import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init(store: MusicLibraryStore) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 100),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Dmus Settings"
        window.isRestorable = false
        window.isReleasedWhenClosed = false
        // Hosts the SwiftUI settings view until it is rewritten in AppKit.
        window.contentViewController = NSHostingController(rootView: SettingsView().environment(store))
        window.center()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
#endif
