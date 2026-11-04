import Foundation

// Splits a queued track row's lower line between the album and artist names
// the same way SharedWidthLayout in QueuedTrackRow.swift does on iOS.
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
