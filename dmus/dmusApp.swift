import SwiftUI

extension EnvironmentValues {
    @Entry var musicLibrary = MusicLibrary()
}

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
    @State private var musicLibrary = MusicLibrary()

    init() {
        // Started at launch rather than in a view's .task so loading is
        // independent of view lifecycle.
        let isDemo = CommandLine.arguments.contains("--demo")
        Task.detached(priority: .utility) {
            if isDemo {
                _ = loadDemoMusicLibrary()
                return
            }
            do {
                let musicRootDirectory = try MusicRootDirectory.locate()
                _ = loadMusicLibrary(musicRootDirectory: musicRootDirectory)
            } catch {
                postMusicLibraryLoadDidFail(error)
            }
        }
    }

    var body: some Scene {
        #if os(macOS)
        Window("Dmus", id: "main") {
            // set min content area size
            mainView.frame(minWidth: 640, minHeight: 480)
        }
        .defaultContentAreaSize(width: 900, height: 600)
        #else
        WindowGroup("Dmus") {
            mainView
        }
        #endif
    }

    private var mainView: some View {
        MainView()
            .environment(\.musicLibrary, musicLibrary)
            .onReceive(NotificationCenter.default.publisher(for: .musicLibraryDidLoad)) { notification in
                if let library = notification.object as? MusicLibrary {
                    musicLibrary = library
                }
            }
    }
}
