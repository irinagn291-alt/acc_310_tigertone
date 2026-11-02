import SwiftUI
import UIKit

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #182211
    static let bg = Color(red: 0.094118, green: 0.133333, blue: 0.066667)
    static let bgHex = "#182211"
    /// #222F18
    static let surface = Color(red: 0.133333, green: 0.184314, blue: 0.094118)
    static let surfaceHex = "#222F18"
    /// #EFF2ED
    static let ink = Color(red: 0.937255, green: 0.949020, blue: 0.929412)
    static let inkHex = "#EFF2ED"
    /// #93E25A
    static let accent = Color(red: 0.576471, green: 0.886275, blue: 0.352941)
    static let accentHex = "#93E25A"
    /// #9BB389
    static let muted = Color(red: 0.607843, green: 0.701961, blue: 0.537255)
    static let mutedHex = "#9BB389"
    static let fontFamily = "Copperplate"
}

/// Base-4 spacing. Views use only these values for padding and stack gaps.
enum Spacing {
    static let s4: CGFloat = 4
    static let s8: CGFloat = 8
    static let s12: CGFloat = 12
    static let s16: CGFloat = 16
    static let s20: CGFloat = 20
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
    static let s40: CGFloat = 40
    static let s48: CGFloat = 48
}

/// Section 7.4. Cards and sheets use `card`. Chips and buttons use `chip`.
enum Radius {
    static let card: CGFloat = 12
    static let chip: CGFloat = 8
}

/// Minimum control size. Not a spacing step.
enum Hit {
    static let min: CGFloat = 44
}

/// One spring for state changes. Press timing is the snap personality.
enum Motion {
    static let press = Animation.easeOut(duration: 0.16)
    static let spring = Animation.spring(response: 0.32, dampingFraction: 0.86)
}

/// Copperplate through UIFontMetrics. Six steps. New York above accessibility-1 and on long lines.
enum AppType {
    enum Step {
        case display
        case title
        case headline
        case body
        case caption
        case micro

        var points: CGFloat {
            switch self {
            case .display: 48
            case .title: 28
            case .headline: 22
            case .body: 17
            case .caption: 14
            case .micro: 12
            }
        }

        var textStyle: UIFont.TextStyle {
            switch self {
            case .display: .largeTitle
            case .title: .title2
            case .headline: .headline
            case .body: .body
            case .caption: .caption1
            case .micro: .caption2
            }
        }
    }

    static func uiFont(_ step: Step, dynamicType: DynamicTypeSize, longLine: Bool) -> UIFont {
        let family = (longLine || dynamicType > .accessibility1) ? "New York" : DesignTokens.fontFamily
        let base = named(family, size: step.points)
        let traits = UITraitCollection(preferredContentSizeCategory: dynamicType.contentCategory)
        return UIFontMetrics(forTextStyle: step.textStyle).scaledFont(for: base, compatibleWith: traits)
    }

    static func font(_ step: Step, dynamicType: DynamicTypeSize, longLine: Bool = false) -> Font {
        let ui = uiFont(step, dynamicType: dynamicType, longLine: longLine)
        return Font.custom(ui.fontName, size: ui.pointSize)
    }

    private static func named(_ family: String, size: CGFloat) -> UIFont {
        if let font = UIFont(name: family, size: size) {
            return font
        }
        if family == "New York", let font = UIFont(name: "NewYork-Regular", size: size) {
            return font
        }
        let descriptor = UIFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif)
            ?? UIFont.systemFont(ofSize: size).fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }
}

extension DynamicTypeSize {
    var contentCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}

extension View {
    func appFont(_ step: AppType.Step, longLine: Bool = false) -> some View {
        modifier(AppFontModifier(step: step, longLine: longLine))
    }
}

private struct AppFontModifier: ViewModifier {
    var step: AppType.Step
    var longLine: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.font(AppType.font(step, dynamicType: dynamicTypeSize, longLine: longLine))
    }
}
