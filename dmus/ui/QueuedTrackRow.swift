import SwiftUI

struct QueuedTrackRow: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(track.trackName)
                .lineLimit(1)
            SplitLayout(leadingFraction: 0.6) {
                Text(track.albumName)
                    .lineLimit(1)
                    .padding(.trailing, 8)
                Text(track.artistName)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

// Divides the width between two subviews at a fixed fraction. GeometryReader
// would expand to fill the List row's height, and an HStack of flexible frames
// only splits evenly, so neither gives a fixed 60/40 split inside a row.
private struct SplitLayout: Layout {
    let leadingFraction: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let height = zip(subviews, widths(for: width)).map { subview, width in
            subview.sizeThatFits(ProposedViewSize(width: width, height: proposal.height)).height
        }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for (subview, width) in zip(subviews, widths(for: bounds.width)) {
            subview.place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(width: width, height: bounds.height)
            )
            x += width
        }
    }

    private func widths(for width: CGFloat) -> [CGFloat] {
        let leading = (width * leadingFraction).rounded(.down)
        return [leading, width - leading]
    }
}

#Preview("Short names") {
    List {
        QueuedTrackRow(track: Track(trackName: "Song", albumName: "Album", artistName: "Artist", path: "/Music/Artist/Album/Song.mp3"))
        QueuedTrackRow(track: Track(trackName: "Loose", albumName: Track.noAlbum, artistName: Track.noArtist, path: "/Music/Loose.m4a"))
    }
}

#Preview("Long names") {
    List {
        QueuedTrackRow(track: Track(
            trackName: "A Track Name Long Enough That It Must Be Elided To Fit The Row",
            albumName: "An Album Name Long Enough That It Must Be Elided To Fit",
            artistName: "An Artist Name Long Enough That It Must Be Elided",
            path: "/Music/Artist/Album/Song.mp3"
        ))
    }
}
