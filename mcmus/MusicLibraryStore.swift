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

    private let fileSystem: any FileSystem
    private let preferences: any Preferences
    // A superseded load still walks to completion since loadMusicLibrary does
    // not check for cancellation, so its result is dropped on arrival instead.
    private var loadGeneration = 0

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
        loadInBackground(isDemo: isDemo, completion: nil)
    }

    // The completion runs on the main actor once the load has finished,
    // whether or not a later load superseded it.
    func loadInBackground(isDemo: Bool, completion: (@Sendable () -> Void)?) {
        let generation = nextLoadGeneration()
        let fileSystem = fileSystem
        let preferences = preferences
        Task.detached(priority: .utility) {
            // Located even in demo mode so the settings dialog can show it.
            var musicRootDirectory: MusicRootDirectory?
            var locateError: NSError?
            do {
                musicRootDirectory = try MusicRootDirectory.locate(fileSystem: fileSystem, preferences: preferences)
            } catch {
                locateError = error as NSError
            }
            await self.setMusicRootDirectory(musicRootDirectory)
            let result = Self.load(
                musicRootDirectory: musicRootDirectory,
                locateError: locateError,
                isDemo: isDemo,
                fileSystem: fileSystem
            )
            await self.finishLoad(result, generation: generation, completion: completion)
        }
    }

    #if os(macOS)
    func changeMusicRootDirectory(to url: URL) {
        changeMusicRootDirectory(to: url, completion: nil)
    }

    func changeMusicRootDirectory(to url: URL, completion: (@Sendable () -> Void)?) {
        guard url.path != musicRootDirectory?.url.path else {
            completion?()
            return
        }
        musicRootDirectory?.stopAccessing(fileSystem: fileSystem)
        let musicRootDirectory = MusicRootDirectory.choose(url, fileSystem: fileSystem, preferences: preferences)
        setMusicRootDirectory(musicRootDirectory)
        let generation = nextLoadGeneration()
        let fileSystem = fileSystem
        Task.detached(priority: .utility) {
            let result = loadMusicLibrary(musicRootDirectory: musicRootDirectory.url, fileSystem: fileSystem)
            await self.finishLoad(result, generation: generation, completion: completion)
        }
    }
    #endif

    private func nextLoadGeneration() -> Int {
        loadGeneration += 1
        return loadGeneration
    }

    private func setMusicRootDirectory(_ musicRootDirectory: MusicRootDirectory?) {
        self.musicRootDirectory = musicRootDirectory
        NotificationCenter.default.post(name: Self.musicRootDirectoryDidChangeNotification, object: self)
    }

    private func finishLoad(_ result: LoadResult, generation: Int, completion: (@Sendable () -> Void)?) {
        if generation == loadGeneration {
            apply(result)
        }
        completion?()
    }

    private nonisolated static func load(
        musicRootDirectory: MusicRootDirectory?,
        locateError: NSError?,
        isDemo: Bool,
        fileSystem: any FileSystem
    ) -> LoadResult {
        if isDemo {
            return loadDemo()
        }
        guard let musicRootDirectory else {
            return LoadResult(library: MusicLibrary(), errors: locateError.map { [$0] } ?? [])
        }
        return loadMusicLibrary(musicRootDirectory: musicRootDirectory.url, fileSystem: fileSystem)
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
