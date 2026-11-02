import SwiftUI

/// Press, quiet, and plain controls. Filled accent is the bordered-prominent verb.
struct SnapButtonStyle: ButtonStyle {
    enum Role {
        case prominent
        case quiet
        case plain
    }

    var role: Role = .plain
    var fills = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(foreground)
            .frame(maxWidth: fills ? .infinity : nil, minHeight: Hit.min)
            .padding(.horizontal, role == .plain ? 0 : Spacing.s16)
            .background { background }
            .overlay { border }
            .contentShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
            .scaleEffect(!reduceMotion && pressed ? 0.97 : 1)
            .opacity(reduceMotion && pressed ? 0.72 : 1)
            .animation(Motion.press, value: pressed)
    }

    private var foreground: Color {
        switch role {
        case .prominent:
            isEnabled ? DesignTokens.bg : DesignTokens.muted
        case .quiet, .plain:
            isEnabled ? DesignTokens.ink : DesignTokens.muted
        }
    }

    @ViewBuilder
    private var background: some View {
        switch role {
        case .prominent:
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .fill(isEnabled ? DesignTokens.accent : DesignTokens.surface)
        case .quiet:
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .fill(.regularMaterial)
        case .plain:
            EmptyView()
        }
    }

    @ViewBuilder
    private var border: some View {
        if role != .plain {
            RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                .strokeBorder(DesignTokens.muted, lineWidth: 1)
        }
    }
}

/// A sheet owns its stack and dismisses with Close.
struct DeskSheet<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var title: String
    var instant: Bool
    @ViewBuilder var content: () -> Content
    @State private var shown: Bool
    @State private var dirty = false
    @State private var confirmLeave = false

    init(title: String, instant: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.instant = instant
        self.content = content
        _shown = State(initialValue: instant)
    }

    var body: some View {
        NavigationStack {
            content()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.regularMaterial, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            if dirty {
                                confirmLeave = true
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .frame(minWidth: Hit.min, minHeight: Hit.min)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Close")
                    }
                }
        }
        .onPreferenceChange(DraftSignal.self) { dirty = $0 }
        .interactiveDismissDisabled(dirty)
        .confirmationDialog("Leave without saving this line?", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("Leave", role: .destructive) { dismiss() }
            Button("Keep writing", role: .cancel) {}
        } message: {
            Text("The line you typed is not saved yet.")
        }
        .scaleEffect(reduceMotion ? 1 : (shown ? 1 : 0.96))
        .opacity(shown ? 1 : 0)
        .onAppear {
            guard !shown else { return }
            if reduceMotion {
                shown = true
            } else {
                withAnimation(Motion.press) { shown = true }
            }
        }
        .presentationCornerRadius(Radius.card)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground {
            Rectangle().fill(.regularMaterial)
        }
    }
}

struct DraftSignal: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    func cardFace() -> some View {
        self
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(.regularMaterial)
            }
    }
}

struct EmptyPage: View {
    var imageName: String
    var headline: String
    var line: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, alignment: .center)
                .containerRelativeFrame(.vertical) { height, _ in height * 0.34 }
                .accessibilityHidden(true)
            Text(headline)
                .appFont(.title)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .appFont(.body, longLine: true)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s16)
            Button(action: action) {
                Text(actionTitle)
                    .appFont(.body)
            }
            .buttonStyle(SnapButtonStyle(role: .prominent, fills: true))
        }
        .padding(Spacing.s20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg.ignoresSafeArea())
    }
}

struct FaultPage: View {
    var retry: () -> Void
    var reset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            Text("Saved books could not be read.")
                .appFont(.title)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Reset is the way forward.")
                .appFont(.body, longLine: true)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s16)
            Button(action: retry) {
                Text("Try again")
                    .appFont(.body)
            }
            .buttonStyle(SnapButtonStyle(role: .prominent, fills: true))
            Button(action: reset) {
                Text("Delete all")
                    .appFont(.body)
            }
            .buttonStyle(SnapButtonStyle(role: .quiet, fills: true))
        }
        .padding(Spacing.s20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg.ignoresSafeArea())
    }
}

struct ReturnSlot: Identifiable, Equatable {
    var id: UUID
    var date: Date
    var line: String
    var title: String
    var page: Int?
    var volumeID: UUID
}

enum DayReadout {
    static func label(dayKey: Int, calendar: Calendar = .current) -> String {
        let year = dayKey / 10_000
        let month = (dayKey / 100) % 100
        let day = dayKey % 100
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return "unknown"
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    static func slots(in archive: StubArchive, now: Date = Date(), calendar: Calendar = .current) -> [ReturnSlot] {
        let start = calendar.startOfDay(for: now)
        let year = calendar.component(.year, from: start)
        return archive.well.stubs.compactMap { stub in
            let month = stub.anniversary / 100
            let day = stub.anniversary % 100
            guard let thisYear = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                return nil
            }
            let when = thisYear < start
                ? (calendar.date(from: DateComponents(year: year + 1, month: month, day: day)) ?? thisYear)
                : thisYear
            let resolved = archive.slip(stub.slipID)
            return ReturnSlot(
                id: stub.id,
                date: when,
                line: resolved.map(\.slip.text).flatMap { $0.isEmpty ? nil : $0 } ?? "unknown",
                title: archive.volume(stub.volumeID)?.title ?? "unknown",
                page: resolved?.slip.page,
                volumeID: stub.volumeID
            )
        }
        .sorted { $0.date < $1.date }
    }
}

func refusalNote(for effect: DeskEffect?) -> String? {
    guard case .refused(let reason) = effect else { return nil }
    switch reason {
    case .alreadyNailed:
        return "Already up. Lift it first."
    case .notDue:
        return "Not due. This line waits."
    case .notNailed:
        return "Nothing is up. Nail this line first."
    case .slipMissing:
        return "No line chosen. Pick one, then close the book."
    case .emptyLine:
        return "Write a line first."
    case .pageOutOfRange:
        return "That page is outside this book."
    case .alreadyClosed:
        return "Already closed. This book takes no new line."
    case .notHeld:
        return "This book is already closed."
    case .missingVolume:
        return "That book is missing."
    }
}
