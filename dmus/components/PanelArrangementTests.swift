import Foundation
import Testing

struct PanelArrangementTests {
    @Test func widerThanTallIsSideBySide() {
        #expect(PanelArrangement(fitting: CGSize(width: 844, height: 390)) == .sideBySide)
    }

    @Test func tallerThanWideIsStacked() {
        #expect(PanelArrangement(fitting: CGSize(width: 390, height: 844)) == .stacked)
    }

    @Test func squareIsStacked() {
        #expect(PanelArrangement(fitting: CGSize(width: 500, height: 500)) == .stacked)
    }
}
