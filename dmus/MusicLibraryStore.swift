import Foundation
import Observation

@Observable
final class MusicLibraryStore {
    private(set) var library = MusicLibrary()
    private(set) var loadErrors: [any Error] = []

    var loadDidFail: Bool { !loadErrors.isEmpty }

    func apply(_ result: LoadResult) {
        library = result.library
        loadErrors = result.errors
    }

    func loadInBackground(isDemo: Bool) {
        Task.detached(priority: .utility) {
            let result = isDemo ? Self.loadDemo() : Self.loadFromMusicRootDirectory()
            await self.apply(result)
        }
    }

    private nonisolated static func loadFromMusicRootDirectory() -> LoadResult {
        do {
            let musicRootDirectory = try MusicRootDirectory.locate()
            return loadMusicLibrary(musicRootDirectory: musicRootDirectory)
        } catch {
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
