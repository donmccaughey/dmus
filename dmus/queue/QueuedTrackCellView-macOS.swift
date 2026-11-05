#if os(macOS)
import AppKit
import Model

final class QueuedTrackCellView: NSTableCellView {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("QueuedTrackCell")

    private static let trackFont = NSFont.preferredFont(forTextStyle: .body)
    private static let detailFont = NSFont.preferredFont(forTextStyle: .subheadline)
    private static let trackLineHeight = lineHeight(of: trackFont)
    private static let detailLineHeight = lineHeight(of: detailFont)
    private static let lineSpacing: CGFloat = 2
    private static let verticalPadding: CGFloat = 4
    private static let horizontalPadding: CGFloat = 8

    // The cell places its labels by hand in layout(), so the table cannot
    // measure a fitting height and takes this fixed one instead.
    static let rowHeight = verticalPadding + trackLineHeight + lineSpacing + detailLineHeight + verticalPadding

    private let trackLabel = makeLabel(font: trackFont, color: .labelColor)
    private let albumLabel = makeLabel(font: detailFont, color: .secondaryLabelColor)
    private let artistLabel = makeLabel(font: detailFont, color: .secondaryLabelColor)

    override init(frame: NSRect) {
        super.init(frame: frame)
        identifier = Self.reuseIdentifier
        artistLabel.alignment = .right
        for label in [trackLabel, albumLabel, artistLabel] {
            addSubview(label)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    func show(_ track: Track) {
        trackLabel.stringValue = track.trackName
        albumLabel.stringValue = track.albumName
        artistLabel.stringValue = track.artistName
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let x = Self.horizontalPadding
        let width = bounds.width - 2 * Self.horizontalPadding
        trackLabel.frame = NSRect(x: x, y: Self.verticalPadding, width: width, height: Self.trackLineHeight)

        let lowerY = Self.verticalPadding + Self.trackLineHeight + Self.lineSpacing
        let widths = LowerLineWidths.split(
            available: width,
            albumIdeal: Self.idealWidth(of: albumLabel),
            artistIdeal: Self.idealWidth(of: artistLabel)
        )
        albumLabel.frame = NSRect(x: x, y: lowerY, width: widths.album, height: Self.detailLineHeight)
        artistLabel.frame = NSRect(
            x: x + width - widths.artist,
            y: lowerY,
            width: widths.artist,
            height: Self.detailLineHeight
        )
    }

    private static func makeLabel(font: NSFont, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = font
        label.textColor = color
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        return label
    }

    // A truncating label's intrinsicContentSize reports the width it was last
    // given, not the width its text wants, so measure the cell directly.
    private static func idealWidth(of label: NSTextField) -> CGFloat {
        label.cell?.cellSize.width ?? 0
    }

    private static func lineHeight(of font: NSFont) -> CGFloat {
        NSLayoutManager().defaultLineHeight(for: font).rounded(.up)
    }
}
#endif
