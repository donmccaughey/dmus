import SwiftUI

#if os(macOS)
final class DmusAppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
#endif

@main
struct DmusApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: DmusAppDelegate
    #endif
    private let store = MusicLibraryStore()

    init() {
        // Started at launch rather than in a view's .task so loading is
        // independent of view lifecycle.
        store.loadInBackground(isDemo: CommandLine.arguments.contains("--demo"))
    }

    var body: some Scene {
        #if os(macOS)
        Window("Dmus", id: "main") {
            // set min content area size
            mainView.frame(minWidth: 640, minHeight: 480)
        }
        .defaultContentAreaSize(width: 900, height: 600)
        Settings {
            SettingsView().environment(store)
        }
        #else
        WindowGroup("Dmus") {
            mainView
        }
        #endif
    }

    private var mainView: some View {
        MainView().environment(store)
    }
}
