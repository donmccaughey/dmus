import Foundation
import Testing

struct LowerLineWidthsTests {
    @Test func bothFitSoEachTakesItsIdealWidth() {
        let widths = LowerLineWidths.split(available: 300, albumIdeal: 100, artistIdeal: 80)
        #expect(widths.album == 100)
        #expect(widths.artist == 192)
    }

    @Test func bothTooLongSplitsSixtyForty() {
        let widths = LowerLineWidths.split(available: 300, albumIdeal: 500, artistIdeal: 500)
        #expect(widths.album == 172)
        #expect(widths.artist == 120)
    }

    @Test func albumCapIsRoundedDown() {
        let widths = LowerLineWidths.split(available: 301, albumIdeal: 500, artistIdeal: 500)
        #expect(widths.album == 172)
        #expect(widths.artist == 121)
    }

    @Test func longAlbumTakesWhatTheArtistLeaves() {
        let widths = LowerLineWidths.split(available: 300, albumIdeal: 500, artistIdeal: 50)
        #expect(widths.album == 242)
        #expect(widths.artist == 50)
    }

    @Test func longArtistTakesWhatTheAlbumLeaves() {
        let widths = LowerLineWidths.split(available: 300, albumIdeal: 50, artistIdeal: 500)
        #expect(widths.album == 50)
        #expect(widths.artist == 242)
    }

    @Test func albumNeverGoesNegative() {
        let widths = LowerLineWidths.split(available: 10, albumIdeal: 500, artistIdeal: 500)
        #expect(widths.album == 0)
        #expect(widths.artist == 4)
    }
}
