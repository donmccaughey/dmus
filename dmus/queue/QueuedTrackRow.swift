import Model
import SwiftUI

struct QueuedTrackRow: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(track.trackName)
                .lineLimit(1)
            SharedWidthLayout(leadingViewMaxFraction: 0.6) {
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

// Share available width between two subviews, allocate `leadingViewMaxFraction` width
// to the leading view when there's not enough space
private struct SharedWidthLayout: Layout {
    let leadingViewMaxFraction: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let height = zip(subviews, widths(for: width, subviews: subviews)).map { subview, width in
            subview.sizeThatFits(ProposedViewSize(width: width, height: proposal.height)).height
        }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for (subview, width) in zip(subviews, widths(for: bounds.width, subviews: subviews)) {
            subview.place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(width: width, height: bounds.height)
            )
            x += width
        }
    }

    private func widths(for width: CGFloat, subviews: Subviews) -> [CGFloat] {
        let idealWidths = subviews.map { $0.sizeThatFits(.unspecified).width }
        guard idealWidths.count == 2 else { return idealWidths }
        let leadingCap = (width * leadingViewMaxFraction).rounded(.down)
        let leadingAvailable = max(leadingCap, width - idealWidths[1])
        let leading = min(idealWidths[0], leadingAvailable)
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

#Preview("Long album, short artist") {
    List {
        QueuedTrackRow(track: Track(
            trackName: "Song",
            albumName: "An Album Name Long Enough To Need More Than Sixty Percent Of The Row",
            artistName: "Artist",
            path: "/Music/Artist/Album/Song.mp3"
        ))
    }
}

#Preview("Short album, long artist") {
    List {
        QueuedTrackRow(track: Track(
            trackName: "Song",
            albumName: "Album",
            artistName: "An Artist Name Long Enough To Need More Than Forty Percent Of The Row",
            path: "/Music/Artist/Album/Song.mp3"
        ))
    }
}
