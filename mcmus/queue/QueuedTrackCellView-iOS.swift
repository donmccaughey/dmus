#if os(iOS)
import UIKit

final class QueuedTrackCellView: UITableViewCell {
    static let reuseIdentifier = "QueuedTrackCell"

    private static let lineSpacing: CGFloat = 2
    private static let verticalPadding: CGFloat = 11

    private let trackLabel = makeLabel(textStyle: .body, color: .label)
    private let albumLabel = makeLabel(textStyle: .subheadline, color: .secondaryLabel)
    private let artistLabel = makeLabel(textStyle: .subheadline, color: .secondaryLabel)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        artistLabel.textAlignment = .right
        for label in [trackLabel, albumLabel, artistLabel] {
            contentView.addSubview(label)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // The cell places its labels by hand in layoutSubviews(), so the table
    // cannot measure a fitting height and takes this one instead.
    static func rowHeight(for traitCollection: UITraitCollection) -> CGFloat {
        verticalPadding
            + lineHeight(of: .preferredFont(forTextStyle: .body, compatibleWith: traitCollection), in: traitCollection)
            + lineSpacing
            + lineHeight(of: .preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection), in: traitCollection)
            + verticalPadding
    }

    func show(_ track: Track) {
        trackLabel.text = track.trackName
        albumLabel.text = track.albumName
        artistLabel.text = track.artistName
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let margins = contentView.layoutMarginsGuide.layoutFrame
        let trackLineHeight = Self.lineHeight(of: trackLabel.font, in: traitCollection)
        let detailLineHeight = Self.lineHeight(of: albumLabel.font, in: traitCollection)
        trackLabel.frame = CGRect(
            x: margins.minX,
            y: Self.verticalPadding,
            width: margins.width,
            height: trackLineHeight
        )

        let lowerY = Self.verticalPadding + trackLineHeight + Self.lineSpacing
        let widths = LowerLineWidths.split(
            available: margins.width,
            albumIdeal: albumLabel.intrinsicContentSize.width,
            artistIdeal: artistLabel.intrinsicContentSize.width
        )
        albumLabel.frame = CGRect(x: margins.minX, y: lowerY, width: widths.album, height: detailLineHeight)
        artistLabel.frame = CGRect(
            x: margins.maxX - widths.artist,
            y: lowerY,
            width: widths.artist,
            height: detailLineHeight
        )
    }

    private static func makeLabel(textStyle: UIFont.TextStyle, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: textStyle)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    // Whole pixels, so rows and the lines in them land on pixel boundaries.
    private static func lineHeight(of font: UIFont, in traitCollection: UITraitCollection) -> CGFloat {
        let scale = traitCollection.displayScale
        return (font.lineHeight * scale).rounded(.up) / scale
    }
}
#endif
