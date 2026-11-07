#if os(iOS)
import Model
import UIKit

@main
final class MCMusAppDelegate: UIResponder, UIApplicationDelegate {
    let store = MusicLibraryStore()
    let player = Player()

    static var shared: MCMusAppDelegate {
        UIApplication.shared.delegate as! MCMusAppDelegate
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        store.loadInBackground(isDemo: CommandLine.arguments.contains("--demo"))
        return true
    }
}
#endif
