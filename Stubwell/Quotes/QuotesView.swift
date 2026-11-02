import SwiftUI
import UIKit

/// Quotes is the root fold. The excerpt plate stays. Nail and Lift sit on it.
struct QuotesView: View {
    var holdPlaceholder: Bool
    var openShelf: () -> Void
    var openDates: () -> Void
    var openSettings: () -> Void
    var addBook: () -> Void

    @Environment(BoardDesk.self) private var desk
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var dragY: CGFloat = 0
    @State private var plateHeight: CGFloat = Spacing.s48
    @State private var allowMotion = false

    private var face: BoardFace { desk.face }

    private var archive: StubArchive {
        _ = desk.revision
        return desk.snapshot()
    }

    private var slots: [ReturnSlot] {
        DayReadout.slots(in: archive)
    }

    private var showEmpty: Bool {
        face.fold == .blank && archive.fileMarks.isEmpty && archive.well.stubs.isEmpty
    }

    private var plateLine: String {
        switch face.fold {
        case .due, .nailed:
            return face.line.isEmpty ? "unknown" : face.line
        case .bare:
            if let next = slots.first {
                return next.date.formatted(date: .abbreviated, time: .omitted)
            }
            return "Later"
        case .blank:
            return " "
        }
    }

    private var phaseWord: String {
        switch face.fold {
        case .due: "Due"
        case .nailed: "Nailed"
        case .bare, .blank: "Bare"
        }
    }

    private var bookTitle: String {
        archive.volume(face.volumeID ?? UUID())?.title
            ?? slots.first?.title
            ?? "unknown"
    }

    private var downward: CGFloat { max(0, dragY) }

    private var travel: CGFloat { reduceMotion ? 0 : downward }

    private var fade: CGFloat {
        let span = max(plateHeight, 1)
        return 1 - min(1, downward / span) * 0.85
    }

    var body: some View {
        Group {
            if desk.fault != nil && archive.volumes.isEmpty && archive.fileMarks.isEmpty {
                FaultPage(retry: { Task { await desk.retry() } }, reset: { Task { await desk.resetAllData() } })
            } else if showEmpty {
                EmptyPage(
                    imageName: "swl_EmptyHome",
                    headline: "Nothing is due.",
                    line: "File a finished book, and one line comes back on its date.",
                    actionTitle: "Add a book",
                    action: addBook
                )
            } else {
                live
            }
        }
        .background(DesignTokens.bg.ignoresSafeArea())
        .onAppear { allowMotion = true }
    }

    private var live: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s12) {
                    plate
                    Text(phaseWord)
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s8)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .safeAreaInset(edge: .bottom) {
            controls
                .padding(.horizontal, Spacing.s20)
                .padding(.bottom, Spacing.s12)
                .padding(.top, Spacing.s8)
                .background(DesignTokens.bg)
        }
        .redacted(reason: holdPlaceholder && !desk.ready ? .placeholder : [])
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s8) {
                dateLabel
                Spacer(minLength: Spacing.s8)
                headerButtons
            }
            VStack(alignment: .leading, spacing: Spacing.s8) {
                dateLabel
                headerButtons
            }
        }
        .padding(.horizontal, Spacing.s20)
        .padding(.top, Spacing.s8)
    }

    private var dateLabel: some View {
        Text(Date.now, format: .dateTime.month(.abbreviated).day().year())
            .appFont(.caption)
            .foregroundStyle(DesignTokens.ink)
            .lineLimit(1)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var headerButtons: some View {
        HStack(spacing: Spacing.s8) {
            iconButton("books.vertical", "Shelf", openShelf)
            iconButton("calendar", "Coming up", openDates)
            iconButton("gearshape", "Settings", openSettings)
        }
    }

    private var plate: some View {
        // Copperplate at display size clips wide lines; New York wraps the due slip.
        let longLine = plateLine.count > 22
        return BoardPlateView(
            line: plateLine,
            travel: travel,
            fade: fade,
            dynamicType: dynamicTypeSize,
            longLine: longLine
        )
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .padding(Spacing.s4)
        .background {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(.regularMaterial)
        }
        .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: PlateHeightKey.self, value: proxy.size.height)
            }
        }
        .onPreferenceChange(PlateHeightKey.self) { plateHeight = $0 }
        .gesture(face.peelEnabled ? peelGesture : nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plateLine == " " ? "No line" : plateLine)
        .accessibilityValue(phaseWord)
    }

    private var peelGesture: some Gesture {
        DragGesture(minimumDistance: Spacing.s8)
            .updating($dragY) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                guard value.translation.height > plateHeight / 2 else { return }
                desk.peel()
            }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                Text(bookTitle)
                    .appFont(.caption)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.s8)
                pageReadout
                    .layoutPriority(1)
            }

            Button {
                desk.nail()
                if case .nailed = desk.lastEffect {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            } label: {
                Text("Nail this line")
                    .appFont(.caption)
            }
            .buttonStyle(SnapButtonStyle(role: face.nailEnabled ? .prominent : .quiet, fills: true))
            .disabled(!face.nailEnabled)
            .accessibilityHint(face.nailEnabled ? "Puts this line up for the day." : "Next line is later.")

            Button {
                desk.peel()
            } label: {
                Text("Lift this line")
                    .appFont(.caption)
            }
            .buttonStyle(SnapButtonStyle(role: face.peelEnabled ? .prominent : .quiet, fills: true))
            .disabled(!face.peelEnabled)
            .accessibilityHint("Takes the line back down.")

            if let note = refusalNote(for: desk.lastEffect) {
                Text(note)
                    .appFont(.caption)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var pageReadout: some View {
        if let page = face.page ?? slots.first?.page {
            Text(page, format: .number.precision(.fractionLength(0)))
                .appFont(.caption)
                .foregroundStyle(DesignTokens.ink)
                .monospacedDigit()
                .contentTransition(reduceMotion ? .opacity : .numericText(value: Double(page)))
                .animation(allowMotion ? Motion.spring : nil, value: page)
        } else {
            Text("unknown")
                .appFont(.caption)
                .foregroundStyle(DesignTokens.muted)
        }
    }

}

private struct PlateHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = Spacing.s48
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension QuotesView {
    func iconButton(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .appFont(.caption)
                .frame(minWidth: Hit.min, minHeight: Hit.min)
                .contentShape(Rectangle())
        }
        .buttonStyle(SnapButtonStyle(role: .quiet))
        .accessibilityLabel(label)
    }
}
