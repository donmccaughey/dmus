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

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // The generated scene manifest lists no configurations, so UIKit
        // asks here; a configuration with no name has no delegate class
        // until one is set.
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = MCMusSceneDelegate.self
        return configuration
    }
}
#endif
