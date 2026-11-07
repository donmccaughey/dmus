#if os(iOS)
import UIKit

extension UIButton {
    static func bordered(title: String, primaryAction: UIAction? = nil) -> UIButton {
        var configuration = UIButton.Configuration.bordered()
        configuration.title = title
        return UIButton(configuration: configuration, primaryAction: primaryAction)
    }
}
#endif
