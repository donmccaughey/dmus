#if os(macOS)
import AppKit
import Model

@main
final class MCMusAppDelegate: NSObject, NSApplicationDelegate {
    private let store = MusicLibraryStore()
    private let player = Player()
    private lazy var mainWindowController = MainWindowController(store: store, player: player)
    private lazy var settingsWindowController = SettingsWindowController(store: store)

    // The main() that AppKit supplies for a @main delegate only calls
    // NSApplicationMain, which relies on a nib to instantiate the delegate.
    static func main() {
        let delegate = MCMusAppDelegate()
        NSApplication.shared.delegate = delegate
        withExtendedLifetime(delegate) {
            _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        NSApp.mainMenu = MainMenu.make(settingsTarget: self, settingsAction: #selector(showSettings))
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.loadInBackground(isDemo: CommandLine.arguments.contains("--demo"))
        mainWindowController.showWindow(nil)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    @objc func showSettings(_ sender: Any?) {
        settingsWindowController.showWindow(sender)
    }
}
#endif
