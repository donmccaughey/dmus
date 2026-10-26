import Foundation

nonisolated extension Notification.Name {
    static let musicLibraryDidLoad = Notification.Name("cc.donm.dmus.musicLibraryDidLoad")
    static let musicLibraryLoadDidFail = Notification.Name("cc.donm.dmus.musicLibraryLoadDidFail")
}

nonisolated func postMusicLibraryDidLoad(_ library: MusicLibrary) {
    postOnMain(.musicLibraryDidLoad, object: library)
}

nonisolated func postMusicLibraryLoadDidFail(_ error: any Error) {
    postOnMain(.musicLibraryLoadDidFail, object: error)
}

nonisolated private func postOnMain(_ name: Notification.Name, object: (any Sendable)?) {
    Task { @MainActor in
        NotificationCenter.default.post(name: name, object: object)
    }
}
