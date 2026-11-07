import Foundation

public final class LoadResult: NSObject, Sendable {
    public let library: MusicLibrary
    public let errors: [any Error]

    public init(library: MusicLibrary, errors: [any Error]) {
        self.library = library
        self.errors = errors
    }
}
