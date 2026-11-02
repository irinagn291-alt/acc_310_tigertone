import SwiftUI

/// Finished book. The frozen fraction stays. No new line.
struct ClosedPage: View {
    var volumeID: UUID
    @Environment(BoardDesk.self) private var desk

    private var volume: Volume? {
        _ = desk.revision
        return desk.snapshot().volume(volumeID)
    }

    var body: some View {
        Group {
            if let volume {
                loaded(volume)
            } else {
                Text("That book is missing.")
                    .appFont(.title)
                    .foregroundStyle(DesignTokens.ink)
                    .padding(Spacing.s20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .navigationTitle("Finished")
        .navigationBarTitleDisplayMode(.inline)
        .background(DesignTokens.bg.ignoresSafeArea())
    }

    private func loaded(_ volume: Volume) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text(volume.progressFraction, format: .number.precision(.fractionLength(0...1)))
                    .appFont(.display)
                    .foregroundStyle(DesignTokens.accent)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: volume.progressFraction))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Finished")
                    .appFont(.caption)
                    .foregroundStyle(DesignTokens.ink)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                    Text(volume.title)
                        .appFont(.title, longLine: volume.title.count > 28)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Spacing.s8)
                    Text(volume.reread ? "Read again" : "Once")
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .layoutPriority(1)
                }
                Text(volume.author.isEmpty ? "unknown" : volume.author)
                    .appFont(.caption)
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(1)
                VStack(alignment: .leading, spacing: Spacing.s12) {
                    if volume.slips.isEmpty {
                        Text("No line was saved.")
                            .appFont(.body)
                            .foregroundStyle(DesignTokens.ink)
                    } else {
                        ForEach(volume.slips) { slip in
                            HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                                Text(slip.text)
                                    .appFont(.body, longLine: slip.text.count > 48)
                                    .foregroundStyle(DesignTokens.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: Spacing.s8)
                                Text(slip.page, format: .number.precision(.fractionLength(0)))
                                    .appFont(.caption)
                                    .monospacedDigit()
                                    .layoutPriority(1)
                            }
                        }
                    }
                }
                .cardFace()
            }
            .padding(Spacing.s20)
        }
    }
}
