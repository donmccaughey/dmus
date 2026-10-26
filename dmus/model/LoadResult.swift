import Foundation

nonisolated struct LoadResult: Sendable {
    let library: MusicLibrary
    let errors: [any Error]
}
