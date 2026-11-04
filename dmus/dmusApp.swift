#if os(iOS)
import Model
import SwiftUI

@main
struct DmusApp: App {
    private let store = MusicLibraryStore()
    private let player = Player()

    init() {
        // Started at launch rather than in a view's .task so loading is
        // independent of view lifecycle.
        store.loadInBackground(isDemo: CommandLine.arguments.contains("--demo"))
    }

    var body: some Scene {
        WindowGroup("Dmus") {
            MainView().environment(store).environment(player)
        }
    }
}
#endif
