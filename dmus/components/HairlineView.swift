#if os(iOS)
import UIKit

final class HairlineView: UIView {
    var axis: NSLayoutConstraint.Axis {
        didSet {
            guard axis != oldValue else { return }
            invalidateIntrinsicContentSize()
        }
    }

    init(axis: NSLayoutConstraint.Axis = .horizontal) {
        self.axis = axis
        super.init(frame: .zero)
        backgroundColor = .separator
        // Only the thin axis has an intrinsic size, so these keep a stack
        // view from stretching the line's thickness whichever way it runs.
        for layoutAxis in [NSLayoutConstraint.Axis.horizontal, .vertical] {
            setContentHuggingPriority(.required, for: layoutAxis)
            setContentCompressionResistancePriority(.required, for: layoutAxis)
        }
        registerForTraitChanges([UITraitDisplayScale.self]) { (self: Self, _: UITraitCollection) in
            self.invalidateIntrinsicContentSize()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: CGSize {
        let thickness = 1 / traitCollection.displayScale
        switch axis {
        case .horizontal: return CGSize(width: UIView.noIntrinsicMetric, height: thickness)
        case .vertical: return CGSize(width: thickness, height: UIView.noIntrinsicMetric)
        @unknown default: return CGSize(width: UIView.noIntrinsicMetric, height: thickness)
        }
    }
}
#endif
