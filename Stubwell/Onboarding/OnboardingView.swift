import SwiftUI

/// Onboarding is three pages. Skip and Continue both mark the shelf ready.
struct OnboardingView: View {
    var finish: () -> Void
    @State private var page = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            pageBody
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            HStack(spacing: Spacing.s8) {
                Text(page + 1, format: .number.precision(.fractionLength(0)))
                Text("of")
                Text(3, format: .number.precision(.fractionLength(0)))
            }
            .appFont(.caption)
            .foregroundStyle(DesignTokens.muted)
            .accessibilityElement(children: .combine)
            Button(page == 2 ? "Continue" : "Next") {
                if page == 2 {
                    finish()
                } else {
                    page += 1
                }
            }
            .buttonStyle(SnapButtonStyle(role: .prominent, fills: true))
            Button("Skip") {
                finish()
            }
            .buttonStyle(SnapButtonStyle(role: .quiet, fills: true))
        }
        .padding(Spacing.s20)
        .background(DesignTokens.bg.ignoresSafeArea())
    }

    @ViewBuilder
    private var pageBody: some View {
        switch page {
        case 0:
            pageCopy(
                image: "swl_Onboarding1",
                headline: "One line from a finished book.",
                line: "It comes back on that month and day."
            )
        case 1:
            pageCopy(
                image: "swl_Onboarding2",
                headline: "Nail this line when the date returns.",
                line: "Lift it if you put it up by mistake."
            )
        default:
            pageCopy(
                image: "swl_Onboarding3",
                headline: "Lines stay on this device.",
                line: "Close a book, pick one line, and it waits for its date."
            )
        }
    }

    private func pageCopy(image: String, headline: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .containerRelativeFrame(.vertical) { height, _ in height * 0.42 }
                .accessibilityHidden(true)
            Text(headline)
                .appFont(.display, longLine: headline.count > 42)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .appFont(.body, longLine: true)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
