import SwiftUI
import UIKit

/// BoardPlateView is the only UIKit surface.
/// It draws the excerpt and a hairline. Sheets and lists stay in SwiftUI.
struct BoardPlateView: UIViewRepresentable {
    var line: String
    var travel: CGFloat
    var fade: CGFloat
    var dynamicType: DynamicTypeSize
    var longLine: Bool

    func makeUIView(context: Context) -> PlateUIView {
        PlateUIView()
    }

    func updateUIView(_ uiView: PlateUIView, context: Context) {
        uiView.apply(
            line: line,
            travel: travel,
            fade: fade,
            dynamicType: dynamicType,
            longLine: longLine
        )
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: PlateUIView, context: Context) -> CGSize? {
        uiView.apply(
            line: line,
            travel: travel,
            fade: fade,
            dynamicType: dynamicType,
            longLine: longLine
        )
        let width = proposal.width ?? uiView.bounds.width
        return uiView.measuredSize(forWidth: width)
    }
}

final class PlateUIView: UIView {
    let textView = UITextView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        textView.backgroundColor = .clear
        textView.isOpaque = false
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.widthTracksTextView = true
        textView.adjustsFontForContentSizeCategory = true
        textView.isAccessibilityElement = false
        addSubview(textView)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func apply(
        line: String,
        travel: CGFloat,
        fade: CGFloat,
        dynamicType: DynamicTypeSize,
        longLine: Bool
    ) {
        let font = AppType.uiFont(.display, dynamicType: dynamicType, longLine: longLine)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byWordWrapping
        let shown = line.isEmpty ? " " : line
        textView.attributedText = NSAttributedString(
            string: shown,
            attributes: [
                .font: font,
                .foregroundColor: UIColor(DesignTokens.ink),
                .kern: longLine ? 0 : 1.6,
                .paragraphStyle: paragraph
            ]
        )
        textView.transform = CGAffineTransform(translationX: 0, y: travel)
        textView.alpha = fade
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        setNeedsDisplay()
    }

    func measuredSize(forWidth width: CGFloat?) -> CGSize {
        let fallback = UIScreen.main.bounds.width - Spacing.s20 * 2
        let raw = width ?? (bounds.width > 1 ? bounds.width : fallback)
        let proposed = (raw.isFinite && raw > 1) ? raw : fallback
        let textWidth = max(1, proposed - Spacing.s16 * 2)
        textView.textContainer.size = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let fitting = textView.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude))
        let height = max(Hit.min * 2, ceil(fitting.height) + Spacing.s16 * 2)
        return CGSize(width: proposed, height: height)
    }

    override var intrinsicContentSize: CGSize {
        let size = measuredSize(forWidth: bounds.width > 1 ? bounds.width : nil)
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = bounds.insetBy(dx: Spacing.s16, dy: Spacing.s16)
        guard inset.width > 0, inset.height > 0 else {
            textView.frame = bounds
            return
        }
        textView.textContainer.size = CGSize(width: inset.width, height: .greatestFiniteMagnitude)
        let fitting = textView.sizeThatFits(CGSize(width: inset.width, height: .greatestFiniteMagnitude))
        let needsScroll = fitting.height > inset.height + 0.5
        textView.isScrollEnabled = needsScroll
        textView.showsVerticalScrollIndicator = needsScroll
        if needsScroll {
            textView.frame = inset
        } else {
            textView.frame = CGRect(
                x: inset.minX,
                y: inset.minY,
                width: inset.width,
                height: max(fitting.height, Hit.min)
            )
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let hair = bounds.insetBy(dx: Spacing.s12, dy: Spacing.s12)
        guard hair.width > 0, hair.height > 0 else { return }
        context.setStrokeColor(UIColor(DesignTokens.muted).cgColor)
        context.setLineWidth(1)
        context.stroke(hair)
    }
}
