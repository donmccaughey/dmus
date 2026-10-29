import Foundation
import Observation

@Observable
final class MusicLibraryStore {
    private(set) var library = MusicLibrary()
    private(set) var loadErrors: [any Error] = []
    private(set) var musicRootDirectory: URL?
    private(set) var loadTask: Task<Void, Never>?

    private let fileSystem: any FileSystem
    private let preferences: any Preferences

    init(
        fileSystem: any FileSystem = RealFileSystem(),
        preferences: any Preferences = RealPreferences()
    ) {
        self.fileSystem = fileSystem
        self.preferences = preferences
    }

    var loadDidFail: Bool { !loadErrors.isEmpty }

    func apply(_ result: LoadResult) {
        library = result.library
        loadErrors = result.errors
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

    func changeMusicRootDirectory(to url: URL) {
        guard url.path != musicRootDirectory?.path else { return }
        preferences.setMusicRootDirectoryPath(url.path)
        musicRootDirectory = url
        let fileSystem = fileSystem
        loadTask?.cancel()
        loadTask = Task.detached(priority: .utility) {
            let result = loadMusicLibrary(musicRootDirectory: url, fileSystem: fileSystem)
            await self.applyUnlessCancelled(result)
        }
    }

    private func setMusicRootDirectory(_ url: URL?) {
        musicRootDirectory = url
    }

    // A superseded load still walks to completion since loadMusicLibrary does
    // not check for cancellation, so its result is dropped here instead.
    private func applyUnlessCancelled(_ result: LoadResult) {
        guard !Task.isCancelled else { return }
        apply(result)
    }

    private nonisolated static func load(
        _ located: Result<URL, any Error>,
        isDemo: Bool,
        fileSystem: any FileSystem
    ) -> LoadResult {
        if isDemo {
            return loadDemo()
        }
        switch located {
        case .success(let musicRootDirectory):
            return loadMusicLibrary(musicRootDirectory: musicRootDirectory, fileSystem: fileSystem)
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

private struct MissingDemoResource: Error {
    let name: String
}
