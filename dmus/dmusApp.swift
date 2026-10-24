import SwiftUI

extension EnvironmentValues {
    @Entry var musicLibrary = MusicLibrary()
}

@main
struct DmusApp: App {
    @State private var musicLibrary = MusicLibrary()

    init() {
        // Started here rather than in a view's .task so the load runs once even
        // if macOS opens more than one window.
        Task.detached(priority: .utility) {
            do {
                let musicDirectory = try MusicDirectory.locate()
                _ = MusicLibrary.load(musicDirectory: musicDirectory)
            } catch {
                MusicLibrary.postLoadDidFail(error)
            }
        }
    }

    var body: some Scene {
        WindowGroup("Dmus") {
            MainView()
                .environment(\.musicLibrary, musicLibrary)
                .onReceive(NotificationCenter.default.publisher(for: .musicLibraryDidLoad)) { notification in
                    if let library = notification.object as? MusicLibrary {
                        musicLibrary = library
                    }
                }
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 600)
        #endif
    }
}
