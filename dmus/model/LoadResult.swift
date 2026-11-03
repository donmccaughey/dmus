import Foundation
import Model

nonisolated struct LoadResult: Sendable {
    let library: MusicLibrary
    let errors: [any Error]
}
