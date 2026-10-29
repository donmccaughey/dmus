import Foundation

nonisolated struct Track: Hashable, Sendable, Codable {
    let trackName: String
    let albumName: String
    let artistName: String
    let path: String

    static let noAlbum = "(no album)"
    static let noArtist = "(no artist)"
}

nonisolated extension Track {
    init?(
        displayName: String,
        pathExtension: String,
        path: String,
        folderName: String?,
        parentFolderName: String?
    ) {
        guard Track.musicFileExtensions.contains(pathExtension.lowercased()) else { return nil }
        self.init(
            trackName: Track.trackName(displayName: displayName, pathExtension: pathExtension),
            albumName: folderName ?? Track.noAlbum,
            artistName: parentFolderName ?? Track.noArtist,
            path: path
        )
    }

    private static let musicFileExtensions: Set<String> = ["mp3", "m4a"]

    // The display name already omits the extension when the Finder hides it,
    // so only strip an extension that is still present.
    private static func trackName(displayName: String, pathExtension: String) -> String {
        let suffix = "." + pathExtension
        guard !pathExtension.isEmpty,
              displayName.lowercased().hasSuffix(suffix.lowercased())
        else { return displayName }
        return String(displayName.dropLast(suffix.count))
    }
}
