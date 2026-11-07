import Foundation

final class NotificationCounter: NSObject {
    private(set) var count = 0

    init(name: Notification.Name, object: Any?) {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(notified), name: name, object: object)
    }

    @objc private func notified() {
        count += 1
    }
}
