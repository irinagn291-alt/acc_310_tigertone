import SwiftUI

/// Close-and-file. The twist screen: one chosen line becomes an anniversary stub.
struct FilePage: View {
    var volumeID: UUID
    @Environment(BoardDesk.self) private var desk
    @State private var note: String?
    @State private var saving = false

    private var volume: Volume? {
        _ = desk.revision
        return desk.snapshot().volume(volumeID)
    }

    var body: some View {
        Group {
            if let volume, let slip = volume.slips.first {
                loaded(volume, slip: slip)
            } else {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    Text("No line chosen.")
                        .appFont(.title)
                        .foregroundStyle(DesignTokens.ink)
                    Text("Pick one, then close the book.")
                        .appFont(.body, longLine: true)
                        .foregroundStyle(DesignTokens.ink)
                }
                .padding(Spacing.s20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .navigationTitle("Close book")
        .navigationBarTitleDisplayMode(.inline)
        .background(DesignTokens.bg.ignoresSafeArea())
    }

    private func loaded(_ volume: Volume, slip: Slip) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Image("swl_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .containerRelativeFrame(.vertical) { height, _ in height * 0.22 }
                    .accessibilityHidden(true)
                Text("File, then nail")
                    .appFont(.caption)
                    .foregroundStyle(DesignTokens.ink)
                Text(slip.text)
                    .appFont(.title, longLine: slip.text.count > 42)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardFace()
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                    Text(volume.title)
                        .appFont(.body, longLine: volume.title.count > 32)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                    Spacer(minLength: Spacing.s8)
                    Text(slip.page, format: .number.precision(.fractionLength(0)))
                        .appFont(.caption)
                        .monospacedDigit()
                        .layoutPriority(1)
                }
                Text(volume.progressFraction, format: .number.precision(.fractionLength(0...1)))
                    .appFont(.headline)
                    .foregroundStyle(DesignTokens.accent)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: volume.progressFraction))
                Text("This line returns on this date.")
                    .appFont(.body, longLine: true)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Date.now, format: .dateTime.month(.wide).day())
                    .appFont(.display)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let note {
                    Text(note)
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    guard !saving else { return }
                    saving = true
                    desk.close(volumeID: volume.id, slipID: slip.id)
                    saving = false
                    if case .refused = desk.lastEffect {
                        note = refusalNote(for: desk.lastEffect)
                    } else {
                        note = nil
                    }
                } label: {
                    Text("Close book")
                        .appFont(.body)
                }
                .buttonStyle(SnapButtonStyle(role: .prominent, fills: true))
                .disabled(saving || !volume.isHeld)
            }
            .padding(Spacing.s20)
        }
    }
}
