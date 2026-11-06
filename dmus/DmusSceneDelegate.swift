#if os(iOS)
import UIKit

final class DmusSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        // Shown in the iPad app switcher, as the SwiftUI WindowGroup title was.
        windowScene.title = "MC Mus"
        let appDelegate = DmusAppDelegate.shared
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainViewController(store: appDelegate.store, player: appDelegate.player)
        window.makeKeyAndVisible()
        self.window = window
    }
}
#endif
