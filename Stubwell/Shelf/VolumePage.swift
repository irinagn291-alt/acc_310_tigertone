import SwiftUI

/// Held book. Page, one quote-store, reread yes or no, then Close book.
struct VolumePage: View {
    var volumeID: UUID
    @Environment(BoardDesk.self) private var desk
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focus: Field?
    @State private var pageNumber = 1
    @State private var pageField = "1"
    @State private var line = ""
    @State private var readAgain = false
    @State private var selected: UUID?
    @State private var note: String?
    @State private var seeded = false
    @State private var saving = false

    private enum Field: Hashable {
        case page
        case line
    }

    private var volume: Volume? {
        _ = desk.revision
        return desk.snapshot().volume(volumeID)
    }

    private var dirty: Bool {
        !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if let volume, volume.isHeld {
                editor(volume)
            } else if volume != nil {
                ClosedPage(volumeID: volumeID)
            } else {
                missing
            }
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
        .preference(key: DraftSignal.self, value: dirty)
    }

    private func editor(_ volume: Volume) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                Text(volume.progressFraction, format: .number.precision(.fractionLength(0...1)))
                    .appFont(.display)
                    .foregroundStyle(DesignTokens.accent)
                    .monospacedDigit()
                    .contentTransition(reduceMotion ? .opacity : .numericText(value: volume.progressFraction))
                    .animation(Motion.spring, value: volume.progressFraction)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Read")
                    .appFont(.caption)
                    .foregroundStyle(DesignTokens.ink)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                    Text(volume.title)
                        .appFont(.title, longLine: volume.title.count > 28)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Spacing.s8)
                    Text(volume.totalPages, format: .number.precision(.fractionLength(0)))
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .monospacedDigit()
                        .layoutPriority(1)
                }
                Text(volume.author.isEmpty ? "unknown" : volume.author)
                    .appFont(.caption)
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(1)
                Toggle("Read again", isOn: $readAgain)
                    .appFont(.body)
                    .tint(DesignTokens.accent)
                    .frame(minHeight: Hit.min)
                    .onChange(of: readAgain) { _, value in
                        _ = desk.setReread(value, on: volume.id)
                    }
                pageRow(volume)
                slipList(volume)
                lineField
                if let note {
                    Text(note)
                        .appFont(.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Spacing.s20)
            .padding(.top, Spacing.s20)
            .padding(.bottom, Spacing.s8)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(DesignTokens.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            bottomChrome(volume)
        }
        .onAppear { seed(volume) }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
    }

    private func bottomChrome(_ volume: Volume) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Button {
                saveLine(on: volume)
            } label: {
                Text("Save line")
                    .appFont(.body)
            }
            .buttonStyle(SnapButtonStyle(role: .quiet, fills: true))
            .disabled(saving || line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button {
                close(volume)
            } label: {
                Text("Close book")
                    .appFont(.body)
            }
            .buttonStyle(SnapButtonStyle(role: .prominent, fills: true))
            .disabled(saving)
        }
        .padding(.horizontal, Spacing.s20)
        .padding(.top, Spacing.s8)
        .padding(.bottom, Spacing.s12)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.bg)
    }

    private func pageRow(_ volume: Volume) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Page")
                .appFont(.caption)
                .foregroundStyle(DesignTokens.muted)
            TextField("Page", text: $pageField)
                .appFont(.body)
                .foregroundStyle(DesignTokens.ink)
                .keyboardType(.numberPad)
                .focused($focus, equals: .page)
                .onChange(of: pageField) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    if digits != newValue {
                        pageField = digits
                        return
                    }
                    guard let value = Int(digits) else { return }
                    guard value >= 1, value <= volume.totalPages else {
                        note = "That page is outside this book."
                        return
                    }
                    note = nil
                    pageNumber = value
                    _ = desk.setPage(value, on: volume.id)
                }
                .padding(Spacing.s12)
                .frame(minHeight: Hit.min)
                .background {
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .fill(DesignTokens.surface)
                }
            Stepper(value: $pageNumber, in: 1...max(volume.totalPages, 1)) {
                Text(pageNumber, format: .number.precision(.fractionLength(0)))
                    .appFont(.body)
                    .foregroundStyle(DesignTokens.ink)
                    .monospacedDigit()
                    .contentTransition(reduceMotion ? .opacity : .numericText(value: Double(pageNumber)))
            }
            .frame(minHeight: Hit.min)
            .onChange(of: pageNumber) { _, newValue in
                pageField = String(newValue)
                if newValue >= 1, newValue <= volume.totalPages {
                    _ = desk.setPage(newValue, on: volume.id)
                }
            }
        }
        .cardFace()
    }

    private func slipList(_ volume: Volume) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("Lines")
                .appFont(.caption)
                .foregroundStyle(DesignTokens.muted)
            if volume.slips.isEmpty {
                Text("No line yet. Write one on this page.")
                    .appFont(.body, longLine: true)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(volume.slips) { slip in
                    Button {
                        selected = slip.id
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                            Image(systemName: selected == slip.id ? "checkmark.circle.fill" : "circle")
                                .accessibilityHidden(true)
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
                        .frame(maxWidth: .infinity, minHeight: Hit.min, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SnapButtonStyle(role: .plain))
                    .accessibilityLabel(slip.text)
                    .accessibilityAddTraits(selected == slip.id ? .isSelected : [])
                }
            }
        }
        .cardFace()
    }

    private var lineField: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("New line")
                .appFont(.caption)
                .foregroundStyle(DesignTokens.muted)
            TextField("New line", text: $line, axis: .vertical)
                .appFont(.body)
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(1...4)
                .focused($focus, equals: .line)
                .padding(Spacing.s12)
                .frame(minHeight: Hit.min)
                .background {
                    RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
                        .fill(DesignTokens.surface)
                }
        }
    }

    private func seed(_ volume: Volume) {
        guard !seeded else { return }
        seeded = true
        pageNumber = volume.currentPage
        pageField = String(volume.currentPage)
        readAgain = volume.reread
        selected = volume.slips.first?.id
    }

    private func saveLine(on volume: Volume) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            note = "Write a line first."
            return
        }
        saving = true
        let result = desk.writeSlip(text: trimmed, page: pageNumber, on: volume.id)
        saving = false
        switch result {
        case .success(let slip):
            selected = slip.id
            line = ""
            note = nil
            focus = nil
        case .failure:
            note = refusalNote(for: desk.lastEffect) ?? "That line could not be saved. Try again."
        }
    }

    private func close(_ volume: Volume) {
        guard let selected else {
            note = "No line chosen. Pick one, then close the book."
            return
        }
        saving = true
        desk.close(volumeID: volume.id, slipID: selected)
        saving = false
        if case .refused = desk.lastEffect {
            note = refusalNote(for: desk.lastEffect)
        } else {
            note = nil
            line = ""
        }
    }

    private var missing: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            Text("That book is missing.")
                .appFont(.title)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Return to the shelf and try again.")
                .appFont(.body, longLine: true)
                .foregroundStyle(DesignTokens.ink)
        }
        .padding(Spacing.s20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.bg.ignoresSafeArea())
    }
}
