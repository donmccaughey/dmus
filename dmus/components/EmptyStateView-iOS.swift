#if os(iOS)
import DeveloperToolsSupport
import UIKit

final class EmptyStateView: UIContentUnavailableView {
    var descriptionText: String {
        get { unavailableConfiguration.secondaryText ?? "" }
        set {
            var updated = unavailableConfiguration
            updated.secondaryText = newValue
            configuration = updated
        }
    }

    // Swift only exposes the superclass's init(configuration:) as a
    // convenience initializer, which a subclass cannot call through super,
    // so this is a convenience initializer too and the class declares no
    // designated ones in order to inherit it.
    convenience init(title: String, systemImage: String, description: String) {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: systemImage)
        configuration.text = title
        configuration.secondaryText = description
        self.init(configuration: configuration)
    }

    private var unavailableConfiguration: UIContentUnavailableConfiguration {
        configuration as! UIContentUnavailableConfiguration
    }
}

#Preview {
    EmptyStateView(title: "No music", systemImage: "folder", description: "The music library is empty.")
}
#endif
