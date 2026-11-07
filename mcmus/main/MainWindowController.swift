#if os(macOS)
import AppKit

final class MainWindowController: NSWindowController, NSWindowDelegate {
    init(store: MusicLibraryStore, player: Player) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MC Mus"
        window.tabbingMode = .disallowed
        window.isRestorable = false
        // Setting the content view controller resizes the window, so it goes
        // before centering and before the autosaved frame is restored.
        window.contentViewController = MainViewController(store: store, player: player)
        window.center()
        super.init(window: window)
        window.delegate = self
        // The controller resets the window's own frame autosave name when it
        // takes the window, so the name has to be set through the controller.
        shouldCascadeWindows = false
        windowFrameAutosaveName = "main"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}
#endif
