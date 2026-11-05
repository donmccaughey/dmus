import Foundation

// Splits a queued track row's lower line between the album and artist names.
// While both fit, each gets the width it needs. While they do not, the album
// with its trailing padding gets up to `albumMaxFraction` of the line, or
// more when the artist name leaves it, and the artist name gets the rest.
nonisolated enum LowerLineWidths {
    static let albumMaxFraction: CGFloat = 0.6
    static let albumTrailingPadding: CGFloat = 8

    static func split(
        available: CGFloat,
        albumIdeal: CGFloat,
        artistIdeal: CGFloat
    ) -> (album: CGFloat, artist: CGFloat) {
        let albumCap = (available * albumMaxFraction).rounded(.down)
        let albumSlotAvailable = max(albumCap, available - artistIdeal)
        let albumSlot = min(albumIdeal + albumTrailingPadding, albumSlotAvailable)
        return (album: max(0, albumSlot - albumTrailingPadding), artist: available - albumSlot)
    }
}
