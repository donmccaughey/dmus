import SwiftUI

@main
struct DmusApp: App {
    var body: some Scene {
        WindowGroup("Dmus") {
            MainView()
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 600)
        #endif
    }
}
