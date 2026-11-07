import Foundation
import Model
import Wrappers

final class MusicLibraryStore {
    static let libraryDidChangeNotification = Notification.Name("MusicLibraryStoreLibraryDidChange")
    // Separate from the library, so a root change alone leaves the files
    // panel, and the macOS outline's expansion, untouched.
    static let musicRootDirectoryDidChangeNotification = Notification.Name("MusicLibraryStoreMusicRootDirectoryDidChange")

    private(set) var library = MusicLibrary()
    private(set) var loadErrors: [any Error] = []
    private(set) var musicRootDirectory: MusicRootDirectory?
    private(set) var loadTask: Task<Void, Never>?

    private let fileSystem: any FileSystem
    private let preferences: any Preferences

    init(fileSystem: any FileSystem, preferences: any Preferences) {
        self.fileSystem = fileSystem
        self.preferences = preferences
    }

    convenience init() {
        self.init(fileSystem: FileSystemReal(), preferences: PreferencesReal())
    }

    var loadDidFail: Bool { !loadErrors.isEmpty }

    func apply(_ result: LoadResult) {
        library = result.library
        loadErrors = result.errors
        NotificationCenter.default.post(name: Self.libraryDidChangeNotification, object: self)
    }

    func loadInBackground(isDemo: Bool) {
        let fileSystem = fileSystem
        let preferences = preferences
        loadTask?.cancel()
        loadTask = Task.detached(priority: .utility) {
            // Located even in demo mode so the settings dialog can show it.
            let located = Result {
                try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)
            }
            await self.setMusicRootDirectory(try? located.get())
            let result = Self.load(located, isDemo: isDemo, fileSystem: fileSystem)
            await self.applyUnlessCancelled(result)
        }
    }

    #if os(macOS)
    func changeMusicRootDirectory(to url: URL) {
        guard url.path != musicRootDirectory?.url.path else { return }
        musicRootDirectory?.stopAccessing(fileSystem: fileSystem)
        let musicRootDirectory = MusicRootDirectory.choose(url, fileSystem: fileSystem, preferences: preferences)
        setMusicRootDirectory(musicRootDirectory)
        let fileSystem = fileSystem
        loadTask?.cancel()
        loadTask = Task.detached(priority: .utility) {
            let result = loadMusicLibrary(musicRootDirectory: musicRootDirectory.url, fileSystem: fileSystem)
            await self.applyUnlessCancelled(result)
        }
    }
    #endif

    private func setMusicRootDirectory(_ musicRootDirectory: MusicRootDirectory?) {
        self.musicRootDirectory = musicRootDirectory
        NotificationCenter.default.post(name: Self.musicRootDirectoryDidChangeNotification, object: self)
    }

    // A superseded load still walks to completion since loadMusicLibrary does
    // not check for cancellation, so its result is dropped here instead.
    private func applyUnlessCancelled(_ result: LoadResult) {
        guard !Task.isCancelled else { return }
        apply(result)
    }

    private nonisolated static func load(
        _ located: Result<MusicRootDirectory, any Error>,
        isDemo: Bool,
        fileSystem: any FileSystem
    ) -> LoadResult {
        if isDemo {
            return loadDemo()
        }
        switch located {
        case .success(let musicRootDirectory):
            return loadMusicLibrary(musicRootDirectory: musicRootDirectory.url, fileSystem: fileSystem)
        case .failure(let error):
            return LoadResult(library: MusicLibrary(), errors: [error])
        }
    }

    private nonisolated static func loadDemo() -> LoadResult {
        do {
            guard let url = Bundle.main.url(forResource: "demo-data", withExtension: "json") else {
                throw MissingDemoResource(name: "demo-data.json")
            }
            guard let trackURL = Bundle.main.url(forResource: "demo-track", withExtension: "mp3") else {
                throw MissingDemoResource(name: "demo-track.mp3")
            }
            let demoData = try Data(contentsOf: url)
            return loadDemoMusicLibrary(demoData: demoData, trackPath: trackURL.path)
        } catch {
            return LoadResult(library: MusicLibrary(), errors: [error])
        }
    }
}

private struct MissingDemoResource: CustomNSError {
    static let errorDomain = "MissingDemoResourceErrorDomain"

    let name: String

    var errorUserInfo: [String: Any] { [NSFilePathErrorKey: name] }
}
