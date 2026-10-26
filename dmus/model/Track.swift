import Foundation

nonisolated struct Track: Hashable, Sendable {
    let trackName: String
    let albumName: String
    let artistName: String
    let path: String

    static let noAlbum = "(no album)"
    static let noArtist = "(no artist)"
}
