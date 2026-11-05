import Foundation

nonisolated enum PanelArrangement: Equatable {
    case sideBySide
    case stacked

    init(fitting size: CGSize) {
        self = size.width > size.height ? .sideBySide : .stacked
    }
}
