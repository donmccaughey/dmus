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
                _ = MusicLibrary.loadDemo()
                return
            }
            do {
                let musicRootDirectory = try MusicRootDirectory.locate()
                _ = MusicLibrary.load(musicRootDirectory: musicRootDirectory)
            } catch {
                MusicLibrary.postLoadDidFail(error)
            }
        }
    }

    var body: some Scene {
        #if os(macOS)
        Window("Dmus", id: "main") {
            mainView
                .frame(minWidth: 640, minHeight: 480)
        }
        // defaultSize measures the whole window frame while the frame modifier
        // above measures the content area below the title bar, so add the
        // title bar height to keep both in content area terms.
        .defaultSize(width: 900, height: 600 + Self.titleBarHeight)
        #else
        WindowGroup("Dmus") {
            mainView
        }
        #endif
    }

    #if os(macOS)
    private static let titleBarHeight: CGFloat = {
        let contentRect = NSRect(x: 0, y: 0, width: 100, height: 100)
        let frameRect = NSWindow.frameRect(forContentRect: contentRect, styleMask: .titled)
        return frameRect.height - contentRect.height
    }()
    #endif

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
